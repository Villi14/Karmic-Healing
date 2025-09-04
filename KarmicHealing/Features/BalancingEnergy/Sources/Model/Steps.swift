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
    .part1step11,
    .part1step12,
    .part1step13,
    .part1step14
  ]

  public static let part2: [Step] = [
    .step1,
    .step2,
    .step3,
    .part2step4,
    .part2step5,
    .part1step11,
    .part1step12,
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
    .part1step11,
    .part1step12,
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
    .init(title: "step_1".loc())
  }

  public static var step2: Self {
    .init(title: "step_2".loc())
  }

  public static var step3: Self {
    .init(
      title: "step_3".loc(),
      description: "step_3_text".loc(),
    )
  }

  public static var part1step4: Self {
    .init(title: "part_1_step_4".loc())
  }

  public static var part1step5: Self {
    .init(title: "part_1_step_5".loc())
  }

  public static var part1step6: Self {
    .init(
      title: "part_1_step_6".loc(),
      description: "part_1_step_6_text".loc()
    )
  }

  public static var part1step7: Self {
    .init(
      title: "part_1_step_6".loc(),
      description: "part_1_step_7_text".loc()
    )
  }

  public static var part1step8: Self {
    .init(
      title: "part_1_step_6".loc(),
      description: "part_1_step_8_text".loc()
    )
  }

  public static var part1step9: Self {
    .init(
      title: "part_1_step_6".loc(),
      description: "part_1_step_9_text".loc()
    )
  }

  public static var part1step10: Self {
    .init(
      title: "part_1_step_10".loc(),
      description: "part_1_step_10_text".loc()
    )
  }

  public static var part1step11: Self {
    .init(title: "part_1_step_11".loc())
  }

  public static var part1step12: Self {
    .init(title: "part_1_step_12".loc())
  }

  public static var part1step13: Self {
    .init(title: "part_1_step_13".loc())
  }

  public static var part1step14: Self {
    .init(title: "part_1_step_14".loc())
  }

  public static var part2step4: Self {
    .init(title: "part_2_step_4".loc())
  }

  public static var part2step5: Self {
    .init(title: "part_2_step_5".loc())
  }

  public static var part2step8: Self {
    .init(title: "part_2_step_8".loc())
  }

  public static var part2step9: Self {
    .init(title: "part_2_step_9".loc())
  }

  public static var part2step10: Self {
    .init(title: "part_2_step_10".loc())
  }

  public static var part2step11: Self {
    .init(title: "part_2_step_11".loc())
  }

  public static var stepLast: Self {
    .init(title: "step_last".loc())
  }

  public static var part3step11: Self {
    .init(title: "part_3_step_11".loc())
  }

  public static var part3step12: Self {
    .init(title: "part_3_step_12".loc())
  }

  public static var part3step13: Self {
    .init(title: "part_3_step_13".loc())
  }

  public static var part3step14: Self {
    .init(title: "part_3_step_14".loc())
  }

  public static var part3step15: Self {
    .init(title: "part_3_step_15".loc())
  }

  public static var part3step16: Self {
    .init(title: "part_3_step_16".loc())
  }

  public static var part3step17: Self {
    .init(title: "part_3_step_17".loc())
  }
}
