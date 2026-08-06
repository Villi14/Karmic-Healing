//
// Karmic Healing 2026
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

@Reducer
public struct PrivacyPolicy {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action: Equatable {}

  public init() {}

  public var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

public struct PrivacyPolicyView: View {
  @Environment(\.dismiss) private var dismiss
  let store: StoreOf<PrivacyPolicy>

  public init(store: StoreOf<PrivacyPolicy>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      AuraBackground(level: .crown)

      VStack(spacing: 0) {
        // Header with close button
        HStack {
          Spacer()
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
              .renderingMode(.template)
              .foregroundStyle(AuraGradient.gradient(for: .crown))
              .font(Typography.icon)
          }
        }
        .padding(.horizontal, DesignConstants.paddingXLarge)
        .padding(.top, DesignConstants.paddingMedium)

        ScrollView {
          VStack(alignment: .leading, spacing: DesignConstants.spacingLarge) {
            // Header
            PolicySectionView(
              title: "privacy_policy_title".loc,
              content: "privacy_policy_last_updated".loc,
              isHeader: true
            )

            // Introduction
            PolicySectionView(
              title: "privacy_policy_intro_title".loc,
              content: "privacy_policy_intro_content".loc
            )

            // Data Collection
            PolicySectionView(
              title: "privacy_policy_data_title".loc,
              content: "privacy_policy_data_content".loc
            )

            // Data Storage
            PolicySectionView(
              title: "privacy_policy_storage_title".loc,
              content: "privacy_policy_storage_content".loc
            )

            // Local Notifications
            PolicySectionView(
              title: "privacy_policy_notifications_title".loc,
              content: "privacy_policy_notifications_content".loc
            )

            // Third Parties
            PolicySectionView(
              title: "privacy_policy_third_party_title".loc,
              content: "privacy_policy_third_party_content".loc
            )

            // Contact
            PolicySectionView(
              title: "privacy_policy_contact_title".loc,
              content: "privacy_policy_contact_content".loc
            )
          }
          .scrollContentBackground(.hidden)
        }
        .padding(.horizontal, DesignConstants.paddingMedium)
      }
    }
  }
}

private struct PolicySectionView: View {
  let title: String
  let content: String
  let isHeader: Bool

  init(title: String, content: String, isHeader: Bool = false) {
    self.title = title
    self.content = content
    self.isHeader = isHeader
  }

  var body: some View {
    VStack(alignment: .leading, spacing: DesignConstants.spacing) {
      Text(title)
        .font(isHeader ? Typography.heading : Typography.title)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .fixedSize(horizontal: false, vertical: true)
        .lineLimit(nil)

      Text(content)
        .font(isHeader ? Typography.label : Typography.body)
        .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        .fixedSize(horizontal: false, vertical: true)
        .lineLimit(nil)
        .multilineTextAlignment(.leading)
    }
    .padding(.bottom, isHeader ? DesignConstants.paddingMedium : 0)
  }
}

#Preview {
  PrivacyPolicyView(store: .init(
    initialState: .init(),
    reducer: {
      PrivacyPolicy()
    }
  ))
}
