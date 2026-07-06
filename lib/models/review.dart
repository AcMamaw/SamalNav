class Review {
  final String authorName;
  final double rating;
  final String comment;
  final DateTime date;
  int helpfulYes;
  int helpfulNo;

  Review({
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
    this.helpfulYes = 0,
    this.helpfulNo = 0,
  });
}

// Global mock storage for reviews, keyed by destination name.
final Map<String, List<Review>> globalReviews = {
  'Isla Reta Beach': [
    Review(authorName: 'Maria Santos', rating: 5.0, comment: 'Ang ganda ng dagat dito! Sobrang linis at clear ang tubig. Highly recommended para sa mga families!', date: DateTime.now().subtract(const Duration(days: 3)), helpfulYes: 32, helpfulNo: 2),
    Review(authorName: 'James Reyes', rating: 5.0, comment: 'Absolutely breathtaking! The crystal-clear waters and powdery white sand are unreal. Best beach in Samal!', date: DateTime.now().subtract(const Duration(days: 8)), helpfulYes: 45, helpfulNo: 1),
    Review(authorName: 'Angelica Cruz', rating: 4.0, comment: 'Maganda pero medyo malayo ang boat ride papunta. Worth it naman ang view pag dating mo na.', date: DateTime.now().subtract(const Duration(days: 21)), helpfulYes: 18, helpfulNo: 3),
    Review(authorName: 'Marco Villanueva', rating: 5.0, comment: 'We spent the whole day here snorkeling and swimming. The water is so clear you can see fish everywhere!', date: DateTime.now().subtract(const Duration(days: 35)), helpfulYes: 27, helpfulNo: 0),
    Review(authorName: 'Carla Bautista', rating: 4.0, comment: 'Sulit na sulit! Bring your own food kasi konti lang ang tindahan dito. But the beach itself is 10/10.', date: DateTime.now().subtract(const Duration(days: 60)), helpfulYes: 14, helpfulNo: 2),
  ],
  'Kaputian Beach': [
    Review(authorName: 'Juan dela Cruz', rating: 5.0, comment: 'Very clean beach with calm, shallow waters. Perfect for family picnics! Daming pwedeng gawin dito.', date: DateTime.now().subtract(const Duration(days: 2)), helpfulYes: 38, helpfulNo: 1),
    Review(authorName: 'Sofia Mendoza', rating: 5.0, comment: 'Our go-to beach every summer! The sand is so fine and the sunset is magical. Babalik-balikan talaga!', date: DateTime.now().subtract(const Duration(days: 10)), helpfulYes: 29, helpfulNo: 0),
    Review(authorName: 'Patrick Gonzales', rating: 4.0, comment: 'Nice place but can get crowded on weekends. Go on weekdays for the best experience.', date: DateTime.now().subtract(const Duration(days: 14)), helpfulYes: 22, helpfulNo: 4),
    Review(authorName: 'Rizal Torres', rating: 5.0, comment: 'Sobrang relaxing! Ang ganda ng buhangin at ang lamig ng hangin. Perfect escape from the city.', date: DateTime.now().subtract(const Duration(days: 30)), helpfulYes: 15, helpfulNo: 1),
    Review(authorName: 'Anna Lim', rating: 4.0, comment: 'Great for kids! Shallow waters make it safe. Food stalls nearby are affordable too.', date: DateTime.now().subtract(const Duration(days: 45)), helpfulYes: 11, helpfulNo: 2),
  ],
  'Canibad Beach': [
    Review(authorName: 'Miguel Santos', rating: 5.0, comment: 'Hidden gem talaga! The cove is secluded and perfect for cliff diving. Adventurous vibes!', date: DateTime.now().subtract(const Duration(days: 5)), helpfulYes: 25, helpfulNo: 1),
    Review(authorName: 'Bianca Reyes', rating: 4.0, comment: 'Ang ganda ng turquoise water! Medyo mahirap ang daan papunta pero sobrang worth it.', date: DateTime.now().subtract(const Duration(days: 15)), helpfulYes: 19, helpfulNo: 3),
    Review(authorName: 'David Garcia', rating: 5.0, comment: 'Best snorkeling spot in Samal! Saw so many colorful fish and corals. Bring your own gear.', date: DateTime.now().subtract(const Duration(days: 28)), helpfulYes: 33, helpfulNo: 0),
    Review(authorName: 'Christine Aquino', rating: 4.0, comment: 'Maganda for adventure seekers! Not recommended for small kids though because of the rocks.', date: DateTime.now().subtract(const Duration(days: 50)), helpfulYes: 12, helpfulNo: 2),
    Review(authorName: 'Leo Fernandez', rating: 3.0, comment: 'Okay naman but limited facilities. Bring everything you need. The cliff jump was awesome though!', date: DateTime.now().subtract(const Duration(days: 75)), helpfulYes: 8, helpfulNo: 5),
  ],
  'Paradise Island': [
    Review(authorName: 'Eleanor Ramos', rating: 5.0, comment: 'Paradise talaga! The resort has everything - pools, water sports, cottages. Super complete!', date: DateTime.now().subtract(const Duration(days: 4)), helpfulYes: 40, helpfulNo: 1),
    Review(authorName: 'Roberto Cruz', rating: 4.0, comment: 'Great family resort. A bit pricey but worth every peso. The beachfront cottages are amazing!', date: DateTime.now().subtract(const Duration(days: 12)), helpfulYes: 28, helpfulNo: 3),
    Review(authorName: 'Michelle Tan', rating: 5.0, comment: 'Nag-enjoy kami ng buo araw! May jet ski, banana boat, at swimming pool pa. Best resort experience!', date: DateTime.now().subtract(const Duration(days: 25)), helpfulYes: 35, helpfulNo: 0),
    Review(authorName: 'Kevin Villanueva', rating: 4.0, comment: 'The place is well-maintained and clean. Staff are friendly. Food is a bit overpriced though.', date: DateTime.now().subtract(const Duration(days: 40)), helpfulYes: 16, helpfulNo: 4),
  ],
  'Hagimit Falls': [
    Review(authorName: 'Carl Mendoza', rating: 5.0, comment: 'Ganda ng falls! Malamig ang tubig at refreshing talaga. Perfect escape from the heat!', date: DateTime.now().subtract(const Duration(days: 6)), helpfulYes: 30, helpfulNo: 1),
    Review(authorName: 'Diana Santos', rating: 4.0, comment: 'The cascading pools are beautiful and perfect for swimming. Nature at its finest!', date: DateTime.now().subtract(const Duration(days: 10)), helpfulYes: 22, helpfulNo: 2),
    Review(authorName: 'Paolo Garcia', rating: 5.0, comment: 'Sobrang relaxing! Ang lamig ng tubig at ang tahimik ng paligid. Must visit for nature lovers!', date: DateTime.now().subtract(const Duration(days: 20)), helpfulYes: 18, helpfulNo: 0),
    Review(authorName: 'Sarah Lee', rating: 4.0, comment: 'Beautiful falls but the trail can be slippery. Wear proper footwear! Worth the short hike.', date: DateTime.now().subtract(const Duration(days: 38)), helpfulYes: 25, helpfulNo: 3),
    Review(authorName: 'Mark Bautista', rating: 5.0, comment: 'Came here with friends for a day trip. We loved every moment! The rock pools are like natural jacuzzis.', date: DateTime.now().subtract(const Duration(days: 55)), helpfulYes: 13, helpfulNo: 1),
  ],
  'Maxima Aquafun': [
    Review(authorName: 'Rica Gonzales', rating: 4.0, comment: 'Super saya! Ang daming activities - zip line, hanging bridge, at forest trails. Worth the price!', date: DateTime.now().subtract(const Duration(days: 7)), helpfulYes: 20, helpfulNo: 2),
    Review(authorName: 'Dennis Torres', rating: 5.0, comment: 'Best adventure park in Samal! The zip line over the forest canopy is thrilling!', date: DateTime.now().subtract(const Duration(days: 18)), helpfulYes: 34, helpfulNo: 1),
    Review(authorName: 'Grace Aquino', rating: 4.0, comment: 'Fun for the whole family! Kids loved the hanging bridges. Sobrang enjoy silang lahat!', date: DateTime.now().subtract(const Duration(days: 32)), helpfulYes: 17, helpfulNo: 3),
    Review(authorName: 'Ryan dela Cruz', rating: 3.0, comment: 'Good park but some activities were closed when we visited. Still had fun with what was available.', date: DateTime.now().subtract(const Duration(days: 65)), helpfulYes: 9, helpfulNo: 5),
  ],
  'Ligid Cave': [
    Review(authorName: 'Adrian Reyes', rating: 4.0, comment: 'Mysterious and exciting! The cave formations are amazing. Make sure to bring a flashlight.', date: DateTime.now().subtract(const Duration(days: 9)), helpfulYes: 15, helpfulNo: 2),
    Review(authorName: 'Jasmine Cruz', rating: 5.0, comment: 'Sobrang astig ng cave! Parang nasa adventure movie. The guide was very knowledgeable and friendly.', date: DateTime.now().subtract(const Duration(days: 22)), helpfulYes: 21, helpfulNo: 0),
    Review(authorName: 'Victor Santos', rating: 4.0, comment: 'Unique experience! Not for the claustrophobic though. The stalactites inside are incredible.', date: DateTime.now().subtract(const Duration(days: 42)), helpfulYes: 12, helpfulNo: 3),
    Review(authorName: 'Nicole Fernandez', rating: 3.0, comment: 'Interesting pero medyo madilim at maputik. Wear old clothes and bring water. Worth trying once!', date: DateTime.now().subtract(const Duration(days: 80)), helpfulYes: 7, helpfulNo: 4),
  ],
  'Mt. Puting Bato': [
    Review(authorName: 'Gabriel Mendoza', rating: 5.0, comment: 'The sunrise view from the top is absolutely stunning! You can see the entire Davao Gulf!', date: DateTime.now().subtract(const Duration(days: 5)), helpfulYes: 38, helpfulNo: 1),
    Review(authorName: 'Isabel Villanueva', rating: 5.0, comment: 'Sobrang ganda ng view! Nakita namin ang buong Davao City mula sa taas. Best hiking spot!', date: DateTime.now().subtract(const Duration(days: 16)), helpfulYes: 29, helpfulNo: 0),
    Review(authorName: 'Antonio Bautista', rating: 4.0, comment: 'The hike is challenging but the panoramic view at the top is worth every step. Bring lots of water!', date: DateTime.now().subtract(const Duration(days: 30)), helpfulYes: 22, helpfulNo: 2),
    Review(authorName: 'Mia Gonzales', rating: 4.0, comment: 'Great for experienced hikers. Start early to catch the sunrise. Ang ganda ng golden hour dito!', date: DateTime.now().subtract(const Duration(days: 48)), helpfulYes: 16, helpfulNo: 3),
  ],
  'Bali-Bali View Deck': [
    Review(authorName: 'Rafael Torres', rating: 5.0, comment: 'Best sunset spot sa Samal! The view deck is well-maintained and the breeze is perfect.', date: DateTime.now().subtract(const Duration(days: 4)), helpfulYes: 25, helpfulNo: 1),
    Review(authorName: 'Camille Santos', rating: 4.0, comment: 'Perfect place for a chill afternoon. Magdala ka ng merienda at mag-enjoy ng view!', date: DateTime.now().subtract(const Duration(days: 13)), helpfulYes: 18, helpfulNo: 2),
    Review(authorName: 'Jerome Aquino', rating: 4.0, comment: 'Affordable entrance fee for such an amazing view. Great photo spot too! Instagrammable!', date: DateTime.now().subtract(const Duration(days: 27)), helpfulYes: 14, helpfulNo: 1),
    Review(authorName: 'Trisha Lim', rating: 5.0, comment: 'Went here for our anniversary date. Sobrang romantic ng sunset view! Highly recommend for couples.', date: DateTime.now().subtract(const Duration(days: 50)), helpfulYes: 20, helpfulNo: 0),
  ],
  'Talikud Island': [
    Review(authorName: 'Eduardo Reyes', rating: 5.0, comment: 'Paradise on earth! Pristine coral reefs and untouched beaches. Parang private island!', date: DateTime.now().subtract(const Duration(days: 3)), helpfulYes: 42, helpfulNo: 1),
    Review(authorName: 'Liza Mendoza', rating: 5.0, comment: 'Sobrang linis ng beach at ang ganda ng coral reef! Perfect for snorkeling and diving!', date: DateTime.now().subtract(const Duration(days: 11)), helpfulYes: 35, helpfulNo: 0),
    Review(authorName: 'Christopher Garcia', rating: 5.0, comment: 'The boat ride there is scenic and the island itself is like a postcard. Truly secluded paradise!', date: DateTime.now().subtract(const Duration(days: 24)), helpfulYes: 28, helpfulNo: 2),
    Review(authorName: 'Andrea Cruz', rating: 4.0, comment: 'Amazing island! Konti lang ang tao kaya very peaceful. Bring your own food and supplies.', date: DateTime.now().subtract(const Duration(days: 40)), helpfulYes: 19, helpfulNo: 3),
    Review(authorName: 'Ramon Santos', rating: 4.0, comment: 'One of the best islands I have visited in the Philippines. The underwater life is incredible!', date: DateTime.now().subtract(const Duration(days: 70)), helpfulYes: 15, helpfulNo: 1),
  ],
  'Vanishing Island': [
    Review(authorName: 'Patricia Villanueva', rating: 5.0, comment: 'Magical experience! Parang nawawala at nag-aappear ang island. Sobrang unique!', date: DateTime.now().subtract(const Duration(days: 2)), helpfulYes: 40, helpfulNo: 1),
    Review(authorName: 'Daniel Bautista', rating: 5.0, comment: 'Truly one of a kind! Standing on a sandbar in the middle of the sea is surreal!', date: DateTime.now().subtract(const Duration(days: 9)), helpfulYes: 33, helpfulNo: 0),
    Review(authorName: 'Kathleen Gonzales', rating: 4.0, comment: 'Amazing pero kailangan mo i-time ang visit mo sa low tide. Check the schedule before going!', date: DateTime.now().subtract(const Duration(days: 19)), helpfulYes: 24, helpfulNo: 4),
    Review(authorName: 'Steven Torres', rating: 5.0, comment: 'The boat tour was fantastic! Our guide was super friendly. The sandbar is photogenic AF!', date: DateTime.now().subtract(const Duration(days: 35)), helpfulYes: 21, helpfulNo: 1),
    Review(authorName: 'Monica Aquino', rating: 4.0, comment: 'Worth the boat trip! Wear reef shoes and bring sunscreen. Ang init ng araw dito pero sobrang worth it!', date: DateTime.now().subtract(const Duration(days: 58)), helpfulYes: 13, helpfulNo: 2),
  ],
  'Coral Garden': [
    Review(authorName: 'Fernando Cruz', rating: 5.0, comment: 'Best snorkeling experience ever! The corals are so vibrant and colorful. Daming tropical fish!', date: DateTime.now().subtract(const Duration(days: 4)), helpfulYes: 36, helpfulNo: 1),
    Review(authorName: 'Jasmine Reyes', rating: 5.0, comment: 'Underwater paradise talaga! We saw clownfish, starfish, at sea urchins. Like Finding Nemo in real life!', date: DateTime.now().subtract(const Duration(days: 14)), helpfulYes: 30, helpfulNo: 0),
    Review(authorName: 'Ricardo Mendoza', rating: 4.0, comment: 'Amazing marine sanctuary. The guided snorkel tour is well-organized. Bring an underwater camera!', date: DateTime.now().subtract(const Duration(days: 26)), helpfulYes: 22, helpfulNo: 2),
    Review(authorName: 'Teresa Santos', rating: 4.0, comment: 'Ganda ng coral formations! Medyo mahal ang tour pero sulit naman sa experience. Must try!', date: DateTime.now().subtract(const Duration(days: 45)), helpfulYes: 17, helpfulNo: 3),
    Review(authorName: 'Benjamin Garcia', rating: 5.0, comment: 'Incredible biodiversity! Saw sea turtles during our dive. This place needs to be protected forever.', date: DateTime.now().subtract(const Duration(days: 90)), helpfulYes: 25, helpfulNo: 1),
  ],
};

// Helper function to get the average rating from a list of reviews.
// Returns the default rating if no reviews exist.
double getAverageRating(String destinationName, double defaultRating) {
  final reviews = globalReviews[destinationName];
  if (reviews == null || reviews.isEmpty) {
    return defaultRating;
  }

  double total = 0;
  for (var review in reviews) {
    total += review.rating;
  }
  return total / reviews.length;
}
