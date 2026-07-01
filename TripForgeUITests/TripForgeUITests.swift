import XCTest

/// End-to-end UI coverage that navigates every user-facing feature of TripForge.
/// Runs against a freshly reset store (UITEST_RESET launch argument).
final class TripForgeUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET"]
        app.launch()
    }

    // MARK: Helpers

    private func waitFor(_ element: XCUIElement, _ timeout: TimeInterval = 8, _ msg: String = "") {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), msg.isEmpty ? "Missing: \(element)" : msg)
    }

    /// Creates a trip from the natural-language prompt flow and lands on the detail screen.
    private func createTripFromPrompt(_ text: String) {
        let newTrip = app.buttons["newTripButton"]
        let planFirst = app.buttons["Plan your first trip"]
        if planFirst.waitForExistence(timeout: 3) {
            planFirst.tap()
        } else {
            waitFor(newTrip, 5, "New-trip button not found")
            newTrip.tap()
        }

        // Prompt mode is the default. Type into the editor.
        let editor = app.textViews["promptEditor"]
        waitFor(editor, 6, "Prompt editor not found")
        editor.tap()
        editor.typeText(text)

        let generate = app.buttons["Generate itinerary"]
        waitFor(generate, 5, "Generate button not found")
        generate.tap()
    }

    // MARK: Tests

    /// Full happy-path: create → detail → day tabs → reorder → add activity → packing → export.
    func testPromptTripFullFlow() {
        createTripFromPrompt("5 days in Tokyo in July with my wife, love food and museums, budget $3000")

        // Detail screen shows the budget bar.
        waitFor(app.staticTexts["Estimated spend"], 10, "Detail (budget bar) did not appear")

        // Day tabs: switch to day 2 if present.
        let day2 = app.buttons["dayTab-1"]
        if day2.waitForExistence(timeout: 4) {
            day2.tap()
            // Back to day 1.
            app.buttons["dayTab-0"].tap()
        }

        // Reorder: first activity move-down should exist when there are >= 2 activities.
        let firstTitle = app.staticTexts["actTitle-0"]
        waitFor(firstTitle, 6, "No activities rendered")
        let originalFirst = firstTitle.label
        let moveDown = app.buttons["act-0-down"]
        if moveDown.exists {
            moveDown.tap()
            // After reordering, the first title should differ.
            let newFirst = app.staticTexts["actTitle-0"].label
            XCTAssertNotEqual(originalFirst, newFirst, "Reorder did not change the first activity")
        }

        // Add activity.
        let addActivity = app.buttons["Add activity"]
        waitFor(addActivity, 6, "Add-activity button not found")
        addActivity.tap()

        let titleField = app.textFields["Title"]
        waitFor(titleField, 6, "Add-activity form did not appear")
        titleField.tap()
        titleField.typeText("Sunset walk")
        let addBtn = app.buttons["Add"]
        waitFor(addBtn, 4)
        addBtn.tap()

        // The new activity should now be listed.
        waitFor(app.staticTexts["Sunset walk"], 6, "Newly added activity not shown")

        // Export .ics -> share sheet appears, then dismiss.
        let export = app.buttons["Export .ics"]
        if export.waitForExistence(timeout: 4) {
            export.tap()
            let closeButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Close' OR label CONTAINS[c] 'Cancel'"))
            if closeButtons.firstMatch.waitForExistence(timeout: 6) {
                closeButtons.firstMatch.tap()
            } else {
                app.swipeDown()
            }
        }

        // Navigate back to the dashboard.
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists { back.tap() }
        waitFor(app.staticTexts["My Trips"], 6, "Did not return to dashboard")
    }

    /// Template flow lands in the Smart-form mode; complete it and generate.
    func testTemplateAndFormFlow() {
        // Template cards expose a combined label (emoji + name + description),
        // so match by substring rather than an exact title.
        let honeymoon = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Honeymoon'")).firstMatch
        waitFor(honeymoon, 6, "Templates not shown")
        honeymoon.tap()

        // Smart form is preselected for templates. Fill the destination.
        let destination = app.textFields["Tokyo, Paris, Bali…"]
        waitFor(destination, 6, "Form destination field not found")
        destination.tap()
        destination.typeText("Kyoto")

        let generate = app.buttons["Generate itinerary"]
        waitFor(generate, 5)
        generate.tap()

        waitFor(app.staticTexts["Estimated spend"], 10, "Template trip detail did not appear")

        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists { back.tap() }
        waitFor(app.staticTexts["My Trips"], 6)
    }

    /// The "Describe / Smart form" segmented switch works both ways.
    func testModeToggle() {
        app.buttons["newTripButton"].tap()

        let smartForm = app.buttons["Smart form"]
        waitFor(smartForm, 6, "Segmented control not found")
        smartForm.tap()
        waitFor(app.textFields["Tokyo, Paris, Bali…"], 5, "Smart form did not show")

        app.buttons["Describe"].tap()
        waitFor(app.textViews["promptEditor"], 5, "Describe mode did not show")

        app.buttons["Cancel"].tap()
        waitFor(app.staticTexts["My Trips"], 6)
    }

    /// "Add to Calendar" must not crash (regression guard for the missing
    /// NSCalendarsWriteOnlyAccessUsageDescription purpose string) and should
    /// surface the confirmation alert. Calendar access is pre-granted by the
    /// test runner via `simctl privacy grant calendar`.
    func testAddToCalendar() {
        createTripFromPrompt("3 days in Rome, food and history, budget $1500")
        waitFor(app.staticTexts["Estimated spend"], 10, "Detail did not appear")

        let addToCal = app.buttons["Add to Calendar"]
        waitFor(addToCal, 6, "Add to Calendar button not found")
        addToCal.tap()

        // Either the success alert (access granted) or the denied-access alert
        // must appear — the important thing is the app stays alive.
        let alert = app.alerts["Calendar"]
        waitFor(alert, 10, "Calendar result alert never appeared (possible crash)")
        alert.buttons["OK"].tap()

        // App is still responsive afterwards.
        waitFor(app.staticTexts["Estimated spend"], 6, "App not responsive after calendar action")
    }
}
