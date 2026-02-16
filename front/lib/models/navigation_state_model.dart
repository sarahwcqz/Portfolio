class NavigationState {
  final bool isNavigating;
  final List<dynamic> instructions;
  final int currentStepIndex;
  final double distanceToNextStep;

  NavigationState({
    required this.isNavigating,
    required this.instructions,
    required this.currentStepIndex,
    required this.distanceToNextStep,
  });

  factory NavigationState.initial() {
    return NavigationState(
      isNavigating: false,
      instructions: [],
      currentStepIndex: 0,
      distanceToNextStep: 0.0,
    );
  }

  NavigationState copyWith({
    bool? isNavigating,
    List<dynamic>? instructions,
    int? currentStepIndex,
    double? distanceToNextStep,
  }) {
    return NavigationState(
      isNavigating: isNavigating ?? this.isNavigating,
      instructions: instructions ?? this.instructions,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      distanceToNextStep: distanceToNextStep ?? this.distanceToNextStep,
    );
  }
}