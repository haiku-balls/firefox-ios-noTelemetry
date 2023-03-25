// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Common
import Foundation
import Shared
import Account
import LocalAuthentication
import Glean

// This file contains all of the settings available in the main settings screen of the app.

private var ShowDebugSettings: Bool = true
private var DebugSettingsClickCount: Int = 0

struct SettingDisclosureUtility {
    static func buildDisclosureIndicator(theme: Theme) -> UIImageView {
        let disclosureIndicator = UIImageView()
        disclosureIndicator.image = UIImage(named: ImageIdentifiers.menuChevron)?.withRenderingMode(.alwaysTemplate).imageFlippedForRightToLeftLayoutDirection()
        disclosureIndicator.tintColor = theme.colors.actionSecondary
        disclosureIndicator.sizeToFit()
        return disclosureIndicator
    }
}

// MARK: - Hidden Settings
/// Used for only for debugging purposes. These settings are hidden behind a
/// 5-tap gesture on the Firefox version cell in the Settings Menu
class HiddenSetting: Setting {
    unowned let settings: SettingsTableViewController

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var hidden: Bool {
        return !ShowDebugSettings
    }

    func updateCell(_ navigationController: UINavigationController?) {
        let controller = navigationController?.topViewController
        let tableView = (controller as? AppSettingsTableViewController)?.tableView
        tableView?.reloadData()
    }
}

class DeleteExportedDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: delete exported databases", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: documentsPath)
            for file in files {
                if file.hasPrefix("browser.") || file.hasPrefix("logins.") {
                    try fileManager.removeItemInDirectory(documentsPath, named: file)
                }
            }
        } catch {}
    }
}

class ExportBrowserDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: copy databases to app container", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            try self.settings.profile.files.copyMatching(fromRelativeDirectory: "", toAbsoluteDirectory: documentsPath) { file in
                return file.hasPrefix("browser.") || file.hasPrefix("logins.") || file.hasPrefix("metadata.")
            }
        } catch {}
    }
}

class ExportLogDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: copy log files to app container", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        DefaultLogger.shared.copyLogsToDocuments()
    }
}

/*
 FeatureSwitchSetting is a boolean switch for features that are enabled via a FeatureSwitch.
 These are usually features behind a partial release and not features released to the entire population.
 */
class FeatureSwitchSetting: BoolSetting {
    let featureSwitch: FeatureSwitch
    let prefs: Prefs

    init(prefs: Prefs, featureSwitch: FeatureSwitch, with title: NSAttributedString) {
        self.featureSwitch = featureSwitch
        self.prefs = prefs
        super.init(prefs: prefs, defaultValue: featureSwitch.isMember(prefs), attributedTitleText: title)
    }

    override var hidden: Bool {
        return !ShowDebugSettings
    }

    override func displayBool(_ control: UISwitch) {
        control.isOn = featureSwitch.isMember(prefs)
    }

    override func writeBool(_ control: UISwitch) {
        self.featureSwitch.setMembership(control.isOn, for: self.prefs)
    }
}

class ForceCrashSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "💥 Debug: Force Crash", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        fatalError("Force crash")
    }
}

class SlowTheDatabase: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: simulate slow database operations", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        debugSimulateSlowDBOperations = !debugSimulateSlowDBOperations
    }
}

class ForgetSyncAuthStateDebugSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(
            string: "Debug: forget Sync auth state",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settings.profile.rustFxA.syncAuthState.invalidate()
        settings.tableView.reloadData()
    }
}

class SentryIDSetting: HiddenSetting {
    let deviceAppHash = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)?.string(forKey: "SentryDeviceAppHash") ?? "0000000000000000000000000000000000000000"
    override var title: NSAttributedString? {
        return NSAttributedString(
            string: "Sentry ID: \(deviceAppHash)",
            attributes: [
                NSAttributedString.Key.foregroundColor: theme.colors.textPrimary,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        copyAppDeviceIDAndPresentAlert(by: navigationController)
    }

    func copyAppDeviceIDAndPresentAlert(by navigationController: UINavigationController?) {
        let alertTitle: String = .SettingsCopyAppVersionAlertTitle
        let alert = AlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        getSelectedCell(by: navigationController)?.setSelected(false, animated: true)
        UIPasteboard.general.string = deviceAppHash
        navigationController?.topViewController?.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alert.dismiss(animated: true)
            }
        }
    }

    func getSelectedCell(by navigationController: UINavigationController?) -> UITableViewCell? {
        let controller = navigationController?.topViewController
        let tableView = (controller as? AppSettingsTableViewController)?.tableView
        guard let indexPath = tableView?.indexPathForSelectedRow else { return nil }
        return tableView?.cellForRow(at: indexPath)
    }
}

class ExperimentsSettings: HiddenSetting {
    override var title: NSAttributedString? { return NSAttributedString(string: "Experiments")}

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(ExperimentsViewController(), animated: true)
    }
}

class TogglePullToRefresh: HiddenSetting, FeatureFlaggable {
    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureEnabled(.pullToRefresh, checking: .userOnly) ? "OFF" : "ON"
        return NSAttributedString(string: "Toggle Pull to Refresh \(toNewStatus)",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let newStatus = !featureFlags.isFeatureEnabled(.pullToRefresh, checking: .userOnly)
        featureFlags.set(feature: .pullToRefresh, to: newStatus)
        updateCell(navigationController)
    }
}

class ResetWallpaperOnboardingPage: HiddenSetting, FeatureFlaggable {
    override var title: NSAttributedString? {
        let seenStatus = UserDefaults.standard.bool(forKey: PrefsKeys.Wallpapers.OnboardingSeenKey) ? "SEEN" : "UNSEEN"
        return NSAttributedString(string: "Reset wallpaper onboarding sheet (\(seenStatus))",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        UserDefaults.standard.set(false, forKey: PrefsKeys.Wallpapers.OnboardingSeenKey)
        updateCell(navigationController)
    }
}

class ToggleInactiveTabs: HiddenSetting, FeatureFlaggable {
    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureEnabled(.inactiveTabs, checking: .userOnly) ? "OFF" : "ON"
        return NSAttributedString(string: "Toggle inactive tabs \(toNewStatus)",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let newStatus = !featureFlags.isFeatureEnabled(.inactiveTabs, checking: .userOnly)
        featureFlags.set(feature: .inactiveTabs, to: newStatus)
        InactiveTabModel.hasRunInactiveTabFeatureBefore = false
        updateCell(navigationController)
    }
}

class ToggleHistoryGroups: HiddenSetting, FeatureFlaggable {
    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureEnabled(.historyGroups, checking: .userOnly) ? "OFF" : "ON"
        return NSAttributedString(
            string: "Toggle history groups \(toNewStatus)",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let newStatus = !featureFlags.isFeatureEnabled(.historyGroups, checking: .userOnly)
        featureFlags.set(feature: .historyGroups, to: newStatus)
        updateCell(navigationController)
    }
}

class ResetContextualHints: HiddenSetting {
    let profile: Profile

    override var accessibilityIdentifier: String? { return "ResetContextualHints.Setting" }

    override var title: NSAttributedString? {
        return NSAttributedString(
            string: "Reset all contextual hints",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        PrefsKeys.ContextualHints.allCases.forEach {
            self.profile.prefs.removeObjectForKey($0.rawValue)
        }
    }
}

class OpenFiftyTabsDebugOption: HiddenSetting {
    override var accessibilityIdentifier: String? { return "OpenFiftyTabsOption.Setting" }

    override var title: NSAttributedString? {
        return NSAttributedString(string: "⚠️ Open 50 `mozilla.org` tabs ⚠️", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let url = URL(string: "https://www.mozilla.org") else { return }

        let object = OpenTabNotificationObject(type: .debugOption(50, url))
        NotificationCenter.default.post(name: .OpenTabNotification, object: object)
    }
}

// Show the current version of Firefox
class VersionSetting: Setting {
    unowned let settings: SettingsTableViewController

    override var accessibilityIdentifier: String? { return "FxVersion" }

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: "\(AppName.shortName) \(AppInfo.appVersion) (\(AppInfo.buildNumber))", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        DebugSettingsClickCount += 1
        if DebugSettingsClickCount >= 5 {
            DebugSettingsClickCount = 0
            ShowDebugSettings = !ShowDebugSettings
            settings.tableView.reloadData()
        }
    }

    override func onLongPress(_ navigationController: UINavigationController?) {
        copyAppVersionAndPresentAlert(by: navigationController)
    }

    func copyAppVersionAndPresentAlert(by navigationController: UINavigationController?) {
        let alertTitle: String = .SettingsCopyAppVersionAlertTitle
        let alert = AlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        getSelectedCell(by: navigationController)?.setSelected(false, animated: true)
        UIPasteboard.general.string = self.title?.string
        navigationController?.topViewController?.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alert.dismiss(animated: true)
            }
        }
    }

    func getSelectedCell(by navigationController: UINavigationController?) -> UITableViewCell? {
        let controller = navigationController?.topViewController
        let tableView = (controller as? AppSettingsTableViewController)?.tableView
        guard let indexPath = tableView?.indexPathForSelectedRow else { return nil }
        return tableView?.cellForRow(at: indexPath)
    }
}

// Opens the license page in a new tab
class LicenseAndAcknowledgementsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsLicenses, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var url: URL? {
        return URL(string: "\(InternalURL.baseUrl)/\(AboutLicenseHandler.path)")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

// Opens the App Store review page of this app
class AppStoreReviewSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .Settings.About.RateOnAppStore, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        RatingPromptManager.goToAppStoreReview()
    }
}

// Opens about:rights page in the content view controller
class YourRightsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsYourRights,
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var url: URL? {
        return URL(string: "https://www.mozilla.org/about/legal/terms/firefox/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

class SendFeedbackSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsSendFeedback, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var url: URL? {
        return URL(string: "https://connect.mozilla.org/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

// Opens the SUMO page in a new tab
class OpenSupportPageSetting: Setting {
    init(delegate: SettingsDelegate?, theme: Theme) {
        super.init(title: NSAttributedString(string: .AppSettingsHelp, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]),
                   delegate: delegate)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true) {
            if let url = URL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.settingsOpenURLInNewTab(url)
            }
        }
    }
}

// Opens the search settings pane
class SearchSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString { return NSAttributedString(string: profile.searchEngines.defaultEngine?.shortName ?? "") }

    override var accessibilityIdentifier: String? { return "Search" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .AppSettingsSearch, attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SearchSettingsTableViewController(profile: profile)

        navigationController?.pushViewController(viewController, animated: true)
    }
}

class LoginsSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!
    weak var navigationController: UINavigationController?
    weak var settings: AppSettingsTableViewController?

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "Logins" }

    init(settings: SettingsTableViewController, delegate: SettingsDelegate?) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        self.navigationController = settings.navigationController
        self.settings = settings as? AppSettingsTableViewController

        super.init(
            title: NSAttributedString(
                string: .Settings.Passwords.Title,
                attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]
            ),
            delegate: delegate
        )
    }

    func deselectRow () {
        if let selectedRow = self.settings?.tableView.indexPathForSelectedRow {
            self.settings?.tableView.deselectRow(at: selectedRow, animated: true)
        }
    }

    override func onClick(_: UINavigationController?) {
        deselectRow()

        guard let navController = navigationController else { return }
        let navigationHandler: (_ url: URL?) -> Void = { url in
            guard let url = url else { return }
            UIWindow.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
            self.delegate?.settingsOpenURLInNewTab(url)
        }

        if AppAuthenticator.canAuthenticateDeviceOwner() {
            if LoginOnboarding.shouldShow() {
                let loginOnboardingViewController = LoginOnboardingViewController(profile: profile, tabManager: tabManager)

                loginOnboardingViewController.doneHandler = {
                    loginOnboardingViewController.dismiss(animated: true)
                }

                loginOnboardingViewController.proceedHandler = {
                    LoginListViewController.create(
                        didShowFromAppMenu: false,
                        authenticateInNavigationController: navController,
                        profile: self.profile,
                        webpageNavigationHandler: navigationHandler
                    ) { loginsVC in
                        guard let loginsVC = loginsVC else { return }
                        navController.pushViewController(loginsVC, animated: true)
                        // Remove the onboarding from the navigation stack so that we go straight back to settings
                        navController.viewControllers.removeAll { viewController in
                            viewController == loginOnboardingViewController
                        }
                    }
                }

                navigationController?.pushViewController(loginOnboardingViewController, animated: true)

                LoginOnboarding.setShown()
            } else {
                LoginListViewController.create(
                    didShowFromAppMenu: false,
                    authenticateInNavigationController: navController,
                    profile: profile,
                    webpageNavigationHandler: navigationHandler
                ) { loginsVC in
                    guard let loginsVC = loginsVC else { return }
                    navController.pushViewController(loginsVC, animated: true)
                }
            }
        } else {
            let viewController = DevicePasscodeRequiredViewController()
            viewController.profile = profile
            viewController.tabManager = tabManager
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

class ContentBlockerSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }
    override var accessibilityIdentifier: String? { return "TrackingProtection" }

    override var status: NSAttributedString? {
        let isOn = profile.prefs.boolForKey(ContentBlockingConfig.Prefs.EnabledKey) ?? ContentBlockingConfig.Defaults.NormalBrowsing

        if isOn {
            let currentBlockingStrength = profile
                .prefs
                .stringForKey(ContentBlockingConfig.Prefs.StrengthKey)
                .flatMap(BlockingStrength.init(rawValue:)) ?? .strict
            return NSAttributedString(string: currentBlockingStrength.settingStatus)
        } else {
            return NSAttributedString(string: .Settings.Homepage.Shortcuts.ToggleOff)
        }
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        super.init(title: NSAttributedString(string: .SettingsTrackingProtectionSectionName, attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = ContentBlockerSettingViewController(prefs: profile.prefs)
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class ClearPrivateDataSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "ClearPrivateData" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let clearTitle: String = .SettingsDataManagementSectionName
        super.init(title: NSAttributedString(string: clearTitle, attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = ClearPrivateDataTableViewController()
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class PrivacyPolicySetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsPrivacyPolicy, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var url: URL? {
        return URL(string: "https://www.mozilla.org/privacy/firefox/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

class NewTabPageSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "NewTab" }

    override var status: NSAttributedString {
        return NSAttributedString(string: NewTabAccessors.getNewTabPage(self.profile.prefs).settingTitle)
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .SettingsNewTabSectionName,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = NewTabContentSettingsViewController(prefs: profile.prefs)
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class HomeSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "Home" }

    override var status: NSAttributedString {
        return NSAttributedString(string: NewTabAccessors.getHomePage(self.profile.prefs).settingTitle)
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .SettingsHomePageSectionName,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = HomePageSettingViewController(prefs: profile.prefs)
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class TabsSetting: Setting {
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "TabsSetting" }

    init(theme: Theme) {
        super.init(title: NSAttributedString(string: .Settings.SectionTitles.TabsTitle,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = TabsSettingsViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class NotificationsSetting: Setting {
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return AccessibilityIdentifiers.Setting.notifications }

    let profile: Profile

    init(theme: Theme, profile: Profile) {
        self.profile = profile
        super.init(title: NSAttributedString(string: .Settings.Notifications.Title,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = NotificationsSettingsViewController(prefs: profile.prefs, hasAccount: profile.hasAccount())
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class NoImageModeSetting: BoolSetting {
    init(settings: SettingsTableViewController) {
        let noImageEnabled = NoImageModeHelper.isActivated(settings.profile.prefs)
        let didChange = { (isEnabled: Bool) in
            NoImageModeHelper.toggle(isEnabled: isEnabled,
                                     profile: settings.profile,
                                     tabManager: settings.tabManager)
        }

        super.init(
            prefs: settings.profile.prefs,
            prefKey: NoImageModePrefsKey.NoImageModeStatus,
            defaultValue: noImageEnabled,
            attributedTitleText: NSAttributedString(string: .Settings.Toggle.NoImageMode),
            attributedStatusText: nil,
            settingDidChange: { isEnabled in
                didChange(isEnabled)
            }
        )
    }

    override var accessibilityIdentifier: String? { return "NoImageMode" }
}

@available(iOS 14.0, *)
class DefaultBrowserSetting: Setting {
    override var accessibilityIdentifier: String? { return "DefaultBrowserSettings" }

    init(theme: Theme) {
        super.init(title: NSAttributedString(string: String.DefaultBrowserMenuItem,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {

        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
    }
}

class OpenWithSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "OpenWith.Setting" }

    override var status: NSAttributedString {
        guard let provider = self.profile.prefs.stringForKey(PrefsKeys.KeyMailToOption) else {
            return NSAttributedString(string: "")
        }
        if let path = Bundle.main.path(forResource: "MailSchemes", ofType: "plist"), let dictRoot = NSArray(contentsOfFile: path) {
            let mailProvider = dictRoot.compactMap({$0 as? NSDictionary }).first { (dict) -> Bool in
                return (dict["scheme"] as? String) == provider
            }
            return NSAttributedString(string: (mailProvider?["name"] as? String) ?? "")
        }
        return NSAttributedString(string: "")
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile

        super.init(title: NSAttributedString(string: .SettingsOpenWithSectionName,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = OpenWithSettingsViewController(prefs: profile.prefs)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class AdvancedAccountSetting: HiddenSetting {
    let profile: Profile

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "AdvancedAccount.Setting" }

    override var title: NSAttributedString? {
        return NSAttributedString(string: .SettingsAdvancedAccountTitle, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = AdvancedAccountSettingViewController()
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }

    override var hidden: Bool {
        return !ShowDebugSettings || profile.hasAccount()
    }
}

class ThemeSetting: Setting {
    let profile: Profile
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }
    override var style: UITableViewCell.CellStyle { return .value1 }
    override var accessibilityIdentifier: String? { return "DisplayThemeOption" }

    override var status: NSAttributedString {
        if LegacyThemeManager.instance.systemThemeIsOn {
            return NSAttributedString(string: .SystemThemeSectionHeader)
        } else if !LegacyThemeManager.instance.automaticBrightnessIsOn {
            return NSAttributedString(string: .DisplayThemeManualStatusLabel)
        } else if LegacyThemeManager.instance.automaticBrightnessIsOn {
            return NSAttributedString(string: .DisplayThemeAutomaticStatusLabel)
        }
        return NSAttributedString(string: "")
    }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .SettingsDisplayThemeTitle,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(ThemeSettingsController(), animated: true)
    }
}

class SearchBarSetting: Setting {
    let viewModel: SearchBarSettingsViewModel

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return AccessibilityIdentifiers.Settings.SearchBar.searchBarSetting }

    override var status: NSAttributedString {
        return NSAttributedString(string: viewModel.searchBarTitle )
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.viewModel = SearchBarSettingsViewModel(prefs: settings.profile.prefs)
        super.init(title: NSAttributedString(string: viewModel.title,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SearchBarSettingsViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
