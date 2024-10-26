import Foundation
import OSLog
import Testing
import os

@testable import ReportCore

@Suite
struct OSLogSpecTests {
    @Test
    func getEntries() async throws {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        // timeIntervalSinceLatestBootはアプリが起動してからのログ
        let position = store.position(timeIntervalSinceLatestBoot: 0)

        let subsystem = "dev.noppe.subsystem.test1"
        let category = #function
        let predicate = NSPredicate(
            format: "category == %@ && subsystem == %@",
            argumentArray: [category, subsystem]
        )
        let entries1 = try store.getEntries(with: .reverse, at: position, matching: predicate)
        #expect(entries1.count(where: { _ in true }) == 0)

        let logger = Logger(
            subsystem: subsystem,
            category: category
        )
        logger.debug("Hello, World!")

        let entries2 = try store.getEntries(with: .reverse, at: position, matching: predicate)
        #expect(entries2.count(where: { _ in true }) == 1)

        // getEntriesしてもstoreからは消えない
        let entries3: some Sequence<OSLogEntry> = try store.getEntries(
            with: .reverse,
            at: position,
            matching: predicate
        )
        #expect(entries3.count(where: { _ in true }) == 1)
        // ただし、iteratorを回した後はentriesから消える
        #expect(entries3.count(where: { _ in true }) == 0)
    }

    @Test
    func getOSLogEntryLog() async throws {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(timeIntervalSinceLatestBoot: 0)

        let subsystem = "dev.noppe.subsystem.test1"
        let category = #function
        let predicate = NSPredicate(
            format: "category == %@ && subsystem == %@",
            argumentArray: [category, subsystem]
        )
        let logger = Logger(
            subsystem: subsystem,
            category: category
        )
        logger.debug("Hello, World!")
        logger.info("Hello, World!")
        logger.notice("Hello, World!")
        logger.error("Hello, World!")
        logger.fault("Hello, World!")

        let entries1 = try store.getEntries(with: .reverse, at: position, matching: predicate)
        let iterator = entries1.makeIterator()
        let logEntry = iterator.next() as! OSLogEntryLog
        print("composedMessage:", logEntry.composedMessage)
        print("date:", logEntry.date)
        print("sender:", logEntry.sender)
        print("processIdentifier:", logEntry.processIdentifier)
        print("threadIdentifier:", logEntry.threadIdentifier)
        print("category:", logEntry.category)
        print("subsystem:", logEntry.subsystem)
        print("level:", logEntry.level.formatted())
        #expect(logEntry.level == .debug)
        #expect((iterator.next() as! OSLogEntryLog).level == .info)
        #expect((iterator.next() as! OSLogEntryLog).level == .notice)
        #expect((iterator.next() as! OSLogEntryLog).level == .error)
        #expect((iterator.next() as! OSLogEntryLog).level == .fault)
        #expect(iterator.next() == nil)
    }

    @Test
    func export() async throws {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(timeIntervalSinceLatestBoot: 0)

        let subsystem = "dev.noppe.subsystem.test1"
        let category = #function
        let predicate = NSPredicate(
            format: "category == %@ && subsystem == %@",
            argumentArray: [category, subsystem]
        )
        let logger = Logger(
            subsystem: subsystem,
            category: category
        )
        logger.debug("Hello, World!")
        logger.info("Hello, World!")
        logger.notice("Hello, World!")
        logger.error("Hello, World!")
        logger.fault("Hello, World!")

        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.log")
        try? FileManager.default.removeItem(at: url)

        try store.write(
            to: url,
            at: position,
            matching: predicate,
            maxLength: 2
        )
        let contents = try String(contentsOf: url, encoding: .utf8)
        var lines = contents.components(separatedBy: .newlines)
        lines.removeLast()  // empty line
        #expect(lines.count == 2)

        // append file
        try store.write(
            to: url,
            at: position,
            matching: predicate,
            maxLength: 2
        )
        let contents2 = try String(contentsOf: url, encoding: .utf8)
        var lines2 = contents2.components(separatedBy: .newlines)
        lines2.removeLast()  // empty line
        #expect(lines2.count == 4)
    }
}
