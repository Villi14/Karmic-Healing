//
// Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

@Reducer
public struct ThemeSettings {
  @Dependency(\.userDefaults) var userDefaults
  @Dependency(\.dismiss) var dismiss

  @ObservableState
  public struct State: Equatable {
    public var userTheme: String

    public init(userTheme: String = "system") {
      self.userTheme = userTheme
    }
  }

  public enum Action: Equatable {
    case onAppear
    case themeChanged(String)
    case done
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { (state: inout State, action: Action) in
      switch action {
      case .onAppear:
        if let saved = userDefaults.string(for: .userTheme), !saved.isEmpty {
          state.userTheme = saved
        }
        return .none

      case let .themeChanged(theme):
        state.userTheme = theme
        return .run { [userDefaults] _ in
          await userDefaults.setAsync(theme, for: .userTheme)
        }

      case .done:
        return .run { _ in
          await dismiss()
        }
      }
    }
  }
}

public struct ThemeSettingsView: View {
  public let store: StoreOf<ThemeSettings>
  @Environment(\.colorScheme) private var systemColorScheme

  public init(store: StoreOf<ThemeSettings>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(spacing: DesignConstants.spacingLarge) {
        titleView
        optionsView(viewStore)
        doneButton(viewStore)
      }
      .frame(maxWidth: DesignConstants.maxWidthMedium)
      .padding(DesignConstants.paddingXLarge)
      .padding(.horizontal, DesignConstants.paddingXXLarge)
      .onAppear {
        viewStore.send(.onAppear)
      }
      .preferredColorScheme(preferredSchemeFor(viewStore.userTheme, systemColorScheme))
    }
  }

  private var titleView: some View {
    Text(String(localized: "theme", bundle: .main))
      .font(.title2.weight(.semibold))
      .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
  }

  private func optionsView(_ viewStore: ViewStoreOf<ThemeSettings>) -> some View {
    VStack(spacing: DesignConstants.paddingMedium) {
      themeButton(themeKey: "system", title: String(localized: "System", bundle: .main), isSelected: viewStore.userTheme == "system", viewStore: viewStore)
      themeButton(themeKey: "light", title: String(localized: "Light", bundle: .main), isSelected: viewStore.userTheme == "light", viewStore: viewStore)
      themeButton(themeKey: "dark", title: String(localized: "Dark", bundle: .main), isSelected: viewStore.userTheme == "dark", viewStore: viewStore)
    }
  }

  private func themeButton(themeKey: String, title: String, isSelected: Bool, viewStore: ViewStoreOf<ThemeSettings>) -> some View {
    Button(action: {
      viewStore.send(.themeChanged(themeKey))
    }) {
      HStack {
        Text(title)
          .font(.body)
          .foregroundStyle(isSelected ? ResourcesAsset.Colors.textPrimary.swiftUIColor : ResourcesAsset.Colors.textSecondary.swiftUIColor)
        Spacer()
        if isSelected {
          Image(systemName: "checkmark")
            .foregroundStyle(ResourcesAsset.Colors.health.swiftUIColor)
        }
      }
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.paddingMedium)
      .background(RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium).fill(ResourcesAsset.Colors.cellBackground.swiftUIColor))
    }
  }

  private func doneButton(_ viewStore: ViewStoreOf<ThemeSettings>) -> some View {
    Button(action: {
      viewStore.send(.done)
    }) {
      Text(String(localized: "done", bundle: .main))
        .font(.headline.weight(.semibold))
        .foregroundStyle(ResourcesAsset.Colors.textInvert.swiftUIColor)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignConstants.paddingLarge)
        .background(
          RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
            .fill(ResourcesAsset.Colors.clam.swiftUIColor)
        )
    }
  }
}

private func preferredSchemeFor(_ theme: String, _ systemScheme: ColorScheme) -> ColorScheme? {
  switch theme {
  case "light": return .light
  case "dark": return .dark
  default: return systemScheme
  }
}


