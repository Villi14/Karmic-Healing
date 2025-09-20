//
// Karmic Healing 2025
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

  public enum Action: Equatable {
    case done
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .done:
        return .none
      }
    }
  }
}

public struct PrivacyPolicyView: View {
  @Environment(\.dismiss) private var dismiss
  let store: StoreOf<PrivacyPolicy>
  
  public init(store: StoreOf<PrivacyPolicy>) {
    self.store = store
  }
  
  public var body: some View {
    VStack(spacing: 0) {
      // Header with close button
      HStack {
        Spacer()
        Button(action: { dismiss() }) {
          Image(systemName: "xmark")
            .renderingMode(.template)
            .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
            .font(.title2)
        }
      }
      .padding(.horizontal, DesignConstants.paddingXLarge)
      .padding(.top, DesignConstants.paddingMedium)
      
      ScrollView {
        VStack(alignment: .leading, spacing: DesignConstants.spacingLarge) {
          // Header
          VStack(alignment: .leading, spacing: DesignConstants.spacing) {
            Text("privacy_policy_title".loc())
              .font(.title2.weight(.bold))
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
            
            Text("privacy_policy_last_updated".loc())
              .font(.caption)
              .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
          }
          .padding(.bottom, DesignConstants.paddingMedium)
          
          // Introduction
          VStack(alignment: .leading, spacing: DesignConstants.spacing) {
            Text("privacy_policy_intro_title".loc())
              .font(.headline.weight(.semibold))
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
            
            Text("privacy_policy_intro_content".loc())
              .font(.body)
              .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
              .multilineTextAlignment(.leading)
          }
          
          // Data Collection
          VStack(alignment: .leading, spacing: DesignConstants.spacing) {
            Text("privacy_policy_data_title".loc())
              .font(.headline.weight(.semibold))
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
            
            Text("privacy_policy_data_content".loc())
              .font(.body)
              .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
              .multilineTextAlignment(.leading)
          }
          
          // Data Storage
          VStack(alignment: .leading, spacing: DesignConstants.spacing) {
            Text("privacy_policy_storage_title".loc())
              .font(.headline.weight(.semibold))
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
            
            Text("privacy_policy_storage_content".loc())
              .font(.body)
              .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
              .multilineTextAlignment(.leading)
          }
          
          // Third Parties
          VStack(alignment: .leading, spacing: DesignConstants.spacing) {
            Text("privacy_policy_third_party_title".loc())
              .font(.headline.weight(.semibold))
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
            
            Text("privacy_policy_third_party_content".loc())
              .font(.body)
              .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
              .multilineTextAlignment(.leading)
          }
          
          // Contact
          VStack(alignment: .leading, spacing: DesignConstants.spacing) {
            Text("privacy_policy_contact_title".loc())
              .font(.headline.weight(.semibold))
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
            
            Text("privacy_policy_contact_content".loc())
              .font(.body)
              .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(nil)
              .multilineTextAlignment(.leading)
          }
        }
        .scrollContentBackground(.hidden)
      }
      .padding(.horizontal, DesignConstants.paddingMedium)
    }
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
