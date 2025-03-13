// Karmic Healing 2025

extension Step {
  public static let part1: [Step] = [
    .step1,
    .step2,
    .step3,
    .part1step4,
    .part1step5,
    .part1step6,
    .part1step7,
    .part1step8,
    .part1step9,
    .part1step10,
    .part1step11
  ]

  public static let part2: [Step] = [
    .step1,
    .step2,
    .step3,
    .part2step4,
    .part2step5,
    .part1step8,
    .part1step9,
    .part2step8,
    .part2step9,
    .part2step10,
    .part2step11,
    .stepLast
  ]

  public static let part3: [Step] = [
    .step1,
    .step2,
    .step3,
    .part2step4,
    .part2step5,
    .part1step8,
    .part1step9,
    .part2step8,
    .part2step9,
    .part2step10,
    .part3step11,
    .part3step12,
    .part3step13,
    .part3step14,
    .part3step15,
    .part3step16,
    .part3step17,
    .stepLast
  ]

  public static var step1: Self {
    .init(title: String(localized: "step_1", bundle: .main))
  }

  public static var step2: Self {
    .init(title: String(localized: "step_2", bundle: .main))
  }

  public static var step3: Self {
    .init(
      title: String(localized: "step_3", bundle: .main),
      description: String(localized: "step_3_text", bundle: .main),
    )
  }

  public static var part1step4: Self {
    .init(title: String(localized: "part_1_step_4", bundle: .main))
  }

  public static var part1step5: Self {
    .init(title: String(localized: "part_1_step_5", bundle: .main))
  }

  public static var part1step6: Self {
    .init(title: String(localized: "part_1_step_6", bundle: .main))
  }

  public static var part1step7: Self {
    .init(
      title: String(localized: "part_1_step_7", bundle: .main),
      description: String(localized: "part_1_step_7_text", bundle: .main),
    )
  }

  public static var part1step8: Self {
    .init(title: String(localized: "part_1_step_8", bundle: .main))
  }

  public static var part1step9: Self {
    .init(title: String(localized: "part_1_step_9", bundle: .main))
  }

  public static var part1step10: Self {
    .init(title: String(localized: "part_1_step_10", bundle: .main))
  }

  public static var part1step11: Self {
    .init(title: String(localized: "part_1_step_11", bundle: .main))
  }

  public static var part2step4: Self {
    .init(title: String(localized: "part_2_step_4", bundle: .main))
  }

  public static var part2step5: Self {
    .init(title: String(localized: "part_2_step_5", bundle: .main))
  }

  public static var part2step8: Self {
    .init(title: String(localized: "part_2_step_8", bundle: .main))
  }

  public static var part2step9: Self {
    .init(title: String(localized: "part_2_step_9", bundle: .main))
  }

  public static var part2step10: Self {
    .init(title: String(localized: "part_2_step_10", bundle: .main))
  }

  public static var part2step11: Self {
    .init(title: String(localized: "part_2_step_11", bundle: .main))
  }

  public static var stepLast: Self {
    .init(title: String(localized: "step_last", bundle: .main))
  }
  
  public static var part3step11: Self {
    .init(title: String(localized: "part_3_step_11", bundle: .main))
  }

  public static var part3step12: Self {
    .init(title: String(localized: "part_3_step_12", bundle: .main))
  }

  public static var part3step13: Self {
    .init(title: String(localized: "part_3_step_13", bundle: .main))
  }

  public static var part3step14: Self {
    .init(title: String(localized: "part_3_step_14", bundle: .main))
  }

  public static var part3step15: Self {
    .init(title: String(localized: "part_3_step_15", bundle: .main))
  }

  public static var part3step16: Self {
    .init(title: String(localized: "part_3_step_16", bundle: .main))
  }

  public static var part3step17: Self {
    .init(title: String(localized: "part_3_step_17", bundle: .main))
  }
}
