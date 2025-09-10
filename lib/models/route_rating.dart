class RouteRating {
  final String userId;
  final double rating;

  RouteRating({
    required this.userId,
    required this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rating': rating,
    };
  }

  factory RouteRating.fromMap(Map<String, dynamic> map) {
    return RouteRating(
      userId: map['userId'] as String,
      rating: (map['rating'] as num).toDouble(),
    );
  }
}
