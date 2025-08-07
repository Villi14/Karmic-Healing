import SharingGRDB
import SwiftUI
import Common
import Resources

struct ItemRowView<ItemType: Identifiable, ListType: Identifiable, DraftType: Identifiable>: View {
  let color: Color
  let isPastDue: Bool
  let notes: String
  let item: ItemType
  let list: ListType
  let showCompleted: Bool
  let isCompleted: Bool
  let isFlagged: Bool
  let title: String
  let priority: Priority?
  let listColor: Color
  
  @Binding var editItem: DraftType?
  @State var isCompletedState: Bool
  
  let onComplete: () -> Void
  let onToggleCompletion: () -> Void
  let onDelete: () -> Void
  let onToggleFlag: () -> Void
  let onEdit: () -> Void
  let onEditCompleted: () -> Void
  let onShowDetails: () -> Void
  let formView: (DraftType, ListType) -> AnyView
  
  init(
    editItem: Binding<DraftType?>,
    color: Color,
    isPastDue: Bool,
    notes: String,
    item: ItemType,
    list: ListType,
    showCompleted: Bool,
    isCompleted: Bool,
    isFlagged: Bool,
    title: String,
    priority: Priority?,
    listColor: Color,
    onComplete: @escaping () -> Void,
    onToggleCompletion: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    onToggleFlag: @escaping () -> Void,
    onEdit: @escaping () -> Void,
    onEditCompleted: @escaping () -> Void,
    onShowDetails: @escaping () -> Void,
    formView: @escaping (DraftType, ListType) -> AnyView
  ) {
    self._editItem = editItem
    self.color = color
    self.isPastDue = isPastDue
    self.notes = notes
    self.item = item
    self.list = list
    self.showCompleted = showCompleted
    self.isCompleted = isCompleted
    self.isFlagged = isFlagged
    self.title = title
    self.priority = priority
    self.listColor = listColor
    self.onComplete = onComplete
    self.onToggleCompletion = onToggleCompletion
    self.onDelete = onDelete
    self.onToggleFlag = onToggleFlag
    self.onEdit = onEdit
    self.onEditCompleted = onEditCompleted
    self.onShowDetails = onShowDetails
    self.formView = formView
    self.isCompletedState = isCompleted
  }
  
  var body: some View {
    HStack {
      HStack(alignment: .firstTextBaseline) {
        Button(action: completeButtonTapped) {
          Image(systemName: isCompletedState ? "circle.inset.filled" : "circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
            .foregroundStyle(ResourcesAsset.Colors.health.swiftUIColor)
            .padding([.trailing], DesignConstants.paddingSmall)
        }
        
        VStack(alignment: .leading) {
          titleView
          
          if !notes.isEmpty {
            Text(notes)
              .font(.subheadline)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .lineLimit(2)
          }
        }
      }
      
      Spacer()
      
      if !isCompletedState {
        HStack {
          if isFlagged {
            Image(systemName: "flag")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(height: DesignConstants.frameHeightSmall)
              .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
          }
          
          Button {
            onEdit()
          } label: {
            Image(systemName: "info.circle")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(height: DesignConstants.frameHeightSmall)
              .foregroundStyle(ResourcesAsset.Colors.clarity.swiftUIColor)
          }
          .tint(color)
        }
      }
    }
    .buttonStyle(.borderless)
    .swipeActions {
      Button(String(localized: "delete", bundle: .main), role: .destructive) {
        onDelete()
      }
      .tint(ResourcesAsset.Colors.energy.swiftUIColor)
      
      Button(isFlagged ? String(localized: "unflag", bundle: .main) : String(localized: "flag", bundle: .main)) {
        onToggleFlag()
      }
      .tint(ResourcesAsset.Colors.friendly.swiftUIColor)
      
      Button(String(localized: "details", bundle: .main)) {
        onShowDetails()
      }
      .tint(ResourcesAsset.Colors.clarity.swiftUIColor)
    }
    .sheet(item: $editItem) { item in
      NavigationStack {
        formView(item, list)
          .navigationTitle(String(localized: "details", bundle: .main))
          .onDisappear {
            onEditCompleted()
          }
      }
    }
    .task(id: isCompletedState) {
      guard !showCompleted else { return }
      
      guard isCompletedState, isCompletedState != isCompleted else { return }
      
      do {
        try await Task.sleep(for: .seconds(2))
        onToggleCompletion()
      } catch {}
    }
  }
  
  private var titleView: some View {
    HStack(alignment: .firstTextBaseline) {
      if let priority = priority {
        Text(String(repeating: "!", count: priority.rawValue))
          .foregroundStyle(isCompletedState ? ResourcesAsset.Colors.textSecondary.swiftUIColor : listColor)
      }
      
      Text(title)
        .foregroundStyle(
          isCompletedState ? ResourcesAsset.Colors.textSecondary.swiftUIColor : ResourcesAsset.Colors.textPrimary.swiftUIColor
        )
    }
    .font(.title3)
  }
  
  private func completeButtonTapped() {
    if showCompleted {
      onToggleCompletion()
    } else {
      isCompletedState.toggle()
    }
  }
} 