import ConsoleCore
import CoreTransferable

struct Document: Transferable {
    let logs: [Log]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .log) {
            let logs = $0.logs

            let url = URL(
                fileURLWithPath: NSTemporaryDirectory()
            )
            .appendingPathComponent("export.log")

            try logs.write(
                to: url
            )

            return .init(url)
        }
    }
}
