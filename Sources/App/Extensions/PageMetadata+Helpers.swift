import Vapor
import Fluent

extension PageMetadata {
    var pages: [Int] {
        guard page <= pageCount else {
            return []
        }

        var pages: [Int] = []
        var index: Int = 0

        for pivot in max(0, page - 5)..<pageCount {
            if index == 9 {
                break
            }

            pages.append(pivot + 1)
            index += 1
        }

        return pages
    }
}
