import XCTest

/// Reproduit la suppression d'une escapade par les deux chemins de l'app
/// et vérifie que l'app survit (régression : crash à la suppression).
final class DeleteDestinationUITests: XCTestCase {

    private func launchSeededApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["--uitest-seed", "-dina.hasOnboarded", "YES"]
        app.launch()
        return app
    }

    private func openJournal(_ app: XCUIApplication) {
        let journalTab = app.buttons["Journal"]
        XCTAssertTrue(journalTab.waitForExistence(timeout: 15), "Onglet Journal introuvable")
        journalTab.tap()
        XCTAssertTrue(app.staticTexts["Cabourg"].firstMatch.waitForExistence(timeout: 10), "Escapade seedée introuvable")
    }

    func testDeleteFromDetailSheet() {
        let app = launchSeededApp()
        openJournal(app)

        app.staticTexts["Cabourg"].firstMatch.tap()

        let deleteButton = app.buttons["Supprimer cette escapade"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 10), "Bouton Supprimer introuvable dans le détail")
        deleteButton.tap()

        let confirm = app.alerts.buttons["Supprimer"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Alerte de confirmation absente")
        confirm.tap()

        sleep(3)
        XCTAssertEqual(app.state, .runningForeground, "L'app a crashé après la suppression (détail)")
        XCTAssertFalse(app.staticTexts["Cabourg"].firstMatch.exists, "L'escapade n'a pas été supprimée")
    }

    func testDeleteFromContextMenu() {
        let app = launchSeededApp()
        openJournal(app)

        app.staticTexts["Cabourg"].firstMatch.press(forDuration: 1.3)

        let delete = app.buttons["Supprimer"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "Menu contextuel Supprimer absent")
        delete.tap()

        sleep(3)
        XCTAssertEqual(app.state, .runningForeground, "L'app a crashé après la suppression (menu contextuel)")
        XCTAssertFalse(app.staticTexts["Cabourg"].firstMatch.exists, "L'escapade n'a pas été supprimée")
    }
}
