class NavigationState {
  final bool isNavigating;
  final List<dynamic> instructions;
  final int currentStepIndex;
  final double distanceToNextStep;
  final double currentHeading;
  final double distanceFromRoute;
  final int deviationCounter;
  final double totalDistanceRemaining;
  final int durationRemaining;

  NavigationState({
    required this.isNavigating,
    required this.instructions,
    required this.currentStepIndex,
    required this.distanceToNextStep,
    this.currentHeading = 0.0,
    this.distanceFromRoute = 0.0,
    this.deviationCounter = 0,
    this.totalDistanceRemaining = 0.0,
    this.durationRemaining = 0,
  });

  factory NavigationState.initial() {
    return NavigationState(
      isNavigating: false,
      instructions: [],
      currentStepIndex: 0,
      distanceToNextStep: 0.0,
      currentHeading: 0.0,
      distanceFromRoute: 0.0,
      deviationCounter: 0,
      totalDistanceRemaining: 0.0,
      durationRemaining: 0,
    );
  }

  NavigationState copyWith({
    bool? isNavigating,
    List<dynamic>? instructions,
    int? currentStepIndex,
    double? distanceToNextStep,
    double? currentHeading,
    double? distanceFromRoute,
    int? deviationCounter,
    double? totalDistanceRemaining,
    int? durationRemaining,
  }) {
    return NavigationState(
      isNavigating: isNavigating ?? this.isNavigating,
      instructions: instructions ?? this.instructions,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      distanceToNextStep: distanceToNextStep ?? this.distanceToNextStep,
      currentHeading: currentHeading ?? this.currentHeading,
      distanceFromRoute: distanceFromRoute ?? this.distanceFromRoute,
      deviationCounter: deviationCounter ?? this.deviationCounter,
      totalDistanceRemaining:
          totalDistanceRemaining ?? this.totalDistanceRemaining,
      durationRemaining: durationRemaining ?? this.durationRemaining,
    );
  }
}
