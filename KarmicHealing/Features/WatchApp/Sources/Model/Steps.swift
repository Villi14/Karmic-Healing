// Karmic Healing 2025

extension Step {
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
    .init(title: "step1")
  }

  public static var step2: Self {
    .init(title: "step2")
  }

  public static var step3: Self {
    .init(
      title: "step3",
      description: "step3text"
    )
  }

  public static var part1step11: Self {
    .init(title: "part1step11")
  }

  public static var part1step12: Self {
    .init(title: "part1step12")
  }

  public static var part2step4: Self {
    .init(title: "part2step4")
  }

  public static var part2step5: Self {
    .init(title: "part2step5")
  }

  public static var part2step8: Self {
    .init(title: "part2step8")
  }

  public static var part2step9: Self {
    .init(title: "part2step9")
  }

  public static var part2step10: Self {
    .init(title: "part2step10")
  }

  public static var part2step11: Self {
    .init(title: "part2step11")
  }

  public static var stepLast: Self {
    .init(title: "steplast")
  }

  public static var part3step11: Self {
    .init(title: "part3step11")
  }

  public static var part3step12: Self {
    .init(title: "part3step12")
  }

  public static var part3step13: Self {
    .init(title: "part3step13")
  }

  public static var part3step14: Self {
    .init(title: "part3step14")
  }

  public static var part3step15: Self {
    .init(title: "part3step15")
  }

  public static var part3step16: Self {
    .init(title: "part3step16")
  }

  public static var part3step17: Self {
    .init(title: "part3step17")
  }
}
