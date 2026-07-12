import XCTest

/// Capture les cinq écrans marketing (accueil, journal, carte, badges,
/// rétrospective) sur le jeu de données « --uitest-screenshots ».
/// Les images sont attachées au résultat de test et s'exportent avec
/// `xcrun xcresulttool export attachments`.
final class MarketingScreenshotTests: XCTestCase {

    func testCaptureMarketingScreenshots() {
        let app = XCUIApplication()
        app.launchArguments += ["--uitest-screenshots", "-dina.hasOnboarded", "YES"]
        app.launch()

        let home = app.buttons["Nouvelle escapade"].firstMatch
        XCTAssertTrue(home.waitForExistence(timeout: 15), "Accueil non affiché")
        allowNotificationsIfAsked(app)
        sleep(2)
        attach(name: "01-accueil")

        app.buttons["Journal"].tap()
        XCTAssertTrue(app.staticTexts["Thaïlande"].firstMatch.waitForExistence(timeout: 10))
        sleep(1)
        attach(name: "02-journal")

        app.buttons["Carte"].tap()
        sleep(4) // chargement des tuiles de la carte
        attach(name: "03-carte")

        app.buttons["Accueil"].tap()
        sleep(1)
        let badgesTile = scrollTo(staticText: "Badges", in: app)
        badgesTile.tap()
        XCTAssertTrue(app.staticTexts["badges"].firstMatch.waitForExistence(timeout: 10))
        sleep(1)
        attach(name: "04-badges")
        app.buttons["Fermer"].tap()
        sleep(1)

        let retroTile = scrollTo(staticText: "Rétrospective", in: app)
        retroTile.tap()
        XCTAssertTrue(app.staticTexts["Rétrospective"].firstMatch.waitForExistence(timeout: 10))
        sleep(1)
        attach(name: "05-retrospective")
    }

    /// Fait défiler l'écran jusqu'à rendre le texte donné visible.
    private func scrollTo(staticText label: String, in app: XCUIApplication) -> XCUIElement {
        let element = app.staticTexts[label].firstMatch
        for _ in 0..<4 where !(element.exists && element.isHittable) {
            app.swipeUp()
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5), "« \(label) » introuvable à l'écran")
        return element
    }

    /// La planification des notifications (anniversaire) déclenche la
    /// demande d'autorisation système : on l'accepte pour dégager l'écran.
    private func allowNotificationsIfAsked(_ app: XCUIApplication) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Autoriser", "Allow"] {
            let button = springboard.buttons[label]
            if button.waitForExistence(timeout: 4) {
                button.tap()
                break
            }
        }
        app.activate()
    }

    /// Attache la capture au résultat de test et, si `SCREENSHOT_DIR` est
    /// défini (variable TEST_RUNNER_SCREENSHOT_DIR côté xcodebuild),
    /// l'écrit aussi en PNG dans ce dossier.
    private func attach(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"]
            ?? NSTemporaryDirectory() + "dinapp-marketing-shots"
        let url = URL(fileURLWithPath: directory).appendingPathComponent("\(name).png")
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: directory),
            withIntermediateDirectories: true
        )
        try? screenshot.pngRepresentation.write(to: url)
    }
}
