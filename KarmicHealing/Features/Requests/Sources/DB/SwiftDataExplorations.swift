// Karmic Healing 2025

import SwiftData
import SwiftUI

@Model
final class RequestsListModel: Equatable, Identifiable {
  var color = 0x4a99ef_ff
  @Relationship
  var requests: [RequestModel]
  var title = ""
  init(
    color: Int = 0x4a99ef_ff,
    requests: [RequestModel] = [],
    title: String = ""
  ) {
    self.color = color
    self.requests = requests
    self.title = title
  }
}

@Model
final class RequestModel: Identifiable {
  var dueDate: Date?
  var isCompleted = 0
  var isFlagged = 0
  var notes = ""
  var priority: Int?
  @Relationship(inverse: \RequestsListModel.requests)
  var requestsList: RequestsListModel
  var title = ""

  init(
    dueDate: Date? = nil,
    isCompleted: Int = 0,
    isFlagged: Int = 0,
    notes: String = "",
    priority: Int? = nil,
    requestsList: RequestsListModel,
    title: String = ""
  ) {
    self.dueDate = dueDate
    self.isCompleted = isCompleted
    self.isFlagged = isFlagged
    self.notes = notes
    self.priority = priority
    self.requestsList = requestsList
    self.title = title
  }
}
enum DetailTypeModel {
  case requestsList(RequestsListModel)
}

@MainActor
func requestsQuery(
  showCompleted: Bool,
  detailType: DetailTypeModel,
  ordering: Ordering
) -> Query<RequestModel, [RequestModel]> {
  let detailTypePredicate: Predicate<RequestModel>
  switch detailType {
  case .requestsList(let requestsList):
    let id = requestsList.id
    detailTypePredicate = #Predicate {
      $0.requestsList.id == id
    }
  }
  let orderingSorts: [SortDescriptor<RequestModel>] = switch ordering {
  case .dueDate:
    [SortDescriptor(\.dueDate)]
  case .priority:
    [
      SortDescriptor(\.priority, order: .reverse),
      SortDescriptor(\.isFlagged, order: .reverse)
    ]
  case .title:
    [SortDescriptor(\.title)]
  }
  return Query(
    filter: #Predicate {
      if !showCompleted {
        $0.isCompleted == 0 && detailTypePredicate.evaluate($0)
      } else {
        detailTypePredicate.evaluate($0)
      }
    },
    sort: [
      SortDescriptor(\.isCompleted)
    ] + orderingSorts,
    animation: .default
  )
}

enum Ordering: String, CaseIterable {
  case dueDate = "Due Date"
  case priority = "Priority"
  case title = "Title"

  var icon: Image {
    switch self {
    case .dueDate: Image(systemName: "calendar")
    case .priority: Image(systemName: "chart.bar.fill")
    case .title: Image(systemName: "textformat.characters")
    }
  }
}

extension Bool {
  var toInt: Int { self ? 1 : 0 }
}

