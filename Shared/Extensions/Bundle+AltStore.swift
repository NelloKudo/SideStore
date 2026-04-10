//
//  Bundle+AltStore.swift
//  AltStore
//
//  Created by Riley Testut on 5/30/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Foundation

public extension Bundle
{
    struct Info
    {
        public static let deviceID = "ALTDeviceID"
        public static let serverID = "ALTServerID"
        public static let certificateID = "ALTCertificateID"
        public static let appGroups = "ALTAppGroups"
        public static let altBundleID = "ALTBundleIdentifier"

        public static let orgbundleIdentifier =  "com.SideStore"
        public static let appbundleIdentifier =  orgbundleIdentifier + ".SideStore"
        public static let devicePairingString = "ALTPairingFile"
        public static let urlTypes = "CFBundleURLTypes"
        public static let exportedUTIs = "UTExportedTypeDeclarations"
        public static let backgroundModes = "UIBackgroundModes"
        
        public static let untetherURL = "ALTFugu14UntetherURL"
        public static let untetherRequired = "ALTFugu14UntetherRequired"
        public static let untetherMinimumiOSVersion = "ALTFugu14UntetherMinimumVersion"
        public static let untetherMaximumiOSVersion = "ALTFugu14UntetherMaximumVersion"
    }
}

public extension Bundle
{
    var infoPlistURL: URL {
        let infoPlistURL = self.bundleURL.appendingPathComponent("Info.plist")
        return infoPlistURL
    }
    
    var provisioningProfileURL: URL {
        let provisioningProfileURL = self.bundleURL.appendingPathComponent("embedded.mobileprovision")
        return provisioningProfileURL
    }
    
    var certificateURL: URL {
        let certificateURL = self.bundleURL.appendingPathComponent("ALTCertificate.p12")
        return certificateURL
    }
    
    var altstorePlistURL: URL {
        let altstorePlistURL = self.bundleURL.appendingPathComponent("AltStore.plist")
        return altstorePlistURL
    }
}

public extension Bundle
{
    static var baseAltStoreAppGroupID = "group." + Bundle.Info.appbundleIdentifier

    var appGroups: [String] {
        return self.infoDictionary?[Bundle.Info.appGroups] as? [String] ?? []
    }
    
    var altstoreAppGroup: String? {
        // Prefer the actual provisioned group embedded in the signing profile.
        // ALTAppGroups in Info.plist lacks the team-ID suffix that the signed
        // entitlement uses, so on iOS 26.4+ (which enforces containerURL
        // entitlements strictly) we must use the real provisioned identifier.
        if let group = altstoreAppGroupFromProvisioningProfile {
            return group
        }
        // Fallback for simulator / unsigned Debug builds.
        return self.appGroups.first { $0.contains(Bundle.baseAltStoreAppGroupID) }
    }

    private var altstoreAppGroupFromProvisioningProfile: String? {
        let profileURL = self.bundleURL.appendingPathComponent("embedded.mobileprovision")
        guard let data = try? Data(contentsOf: profileURL) else { return nil }
        // The profile is CMS-signed binary data with an XML plist payload inside.
        // ISO-8859-1 maps every byte 0-255 to its corresponding Unicode code point,
        // so this preserves raw bytes without lossy conversion.
        let raw = String(data: data, encoding: .isoLatin1) ?? ""
        guard let xmlStart = raw.range(of: "<?xml"),
              let plistEnd = raw.range(of: "</plist>")
        else { return nil }
        let plistString = String(raw[xmlStart.lowerBound ..< plistEnd.upperBound])
        guard let plistData = plistString.data(using: .isoLatin1),
              let plist = (try? PropertyListSerialization.propertyList(from: plistData, format: nil)) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any],
              let groups = entitlements["com.apple.security.application-groups"] as? [String]
        else { return nil }
        return groups.first { $0.contains(Bundle.baseAltStoreAppGroupID) }
    }
    
    var completeInfoDictionary: [String : Any]? {
        let infoPlistURL = self.infoPlistURL
        return NSDictionary(contentsOf: infoPlistURL) as? [String : Any]
    }
}
