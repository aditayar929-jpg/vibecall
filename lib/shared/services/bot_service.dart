import 'dart:math';

/// Bot matching service — simulates real users for single-user experience.
///
/// When no real users are available, bots appear as matches with
/// realistic profiles, animated avatars, and chat responses.
class BotService {
  static final Random _random = Random();

  // ─── Bot Girl Profiles (100+ realistic Indian girls) ─────────
  static final List<Map<String, dynamic>> _botProfiles = [
    // Mumbai
    {'name': 'Aisha', 'age': 22, 'city': 'Mumbai', 'bio': 'Love dancing & travel 💃', 'avatar': 'https://randomuser.me/api/portraits/women/1.jpg', 'interests': ['Dance', 'Travel', 'Music', 'Photography']},
    {'name': 'Priya', 'age': 24, 'city': 'Mumbai', 'bio': 'Foodie & adventure seeker 🍕', 'avatar': 'https://randomuser.me/api/portraits/women/2.jpg', 'interests': ['Cooking', 'Travel', 'Fitness', 'Fashion']},
    {'name': 'Riya', 'age': 21, 'city': 'Mumbai', 'bio': 'Beach lover 🏖️', 'avatar': 'https://randomuser.me/api/portraits/women/3.jpg', 'interests': ['Travel', 'Photography', 'Music', 'Yoga']},
    {'name': 'Tanvi', 'age': 23, 'city': 'Mumbai', 'bio': 'Model & dreamer ✨', 'avatar': 'https://randomuser.me/api/portraits/women/4.jpg', 'interests': ['Fashion', 'Dance', 'Photography', 'Art']},
    {'name': 'Neha', 'age': 25, 'city': 'Mumbai', 'bio': 'Corporate girl by day 🌙', 'avatar': 'https://randomuser.me/api/portraits/women/5.jpg', 'interests': ['Coffee', 'Reading', 'Travel', 'Music']},
    // Delhi
    {'name': 'Ananya', 'age': 22, 'city': 'Delhi', 'bio': 'Bookworm with a wild side 📚', 'avatar': 'https://randomuser.me/api/portraits/women/6.jpg', 'interests': ['Reading', 'Yoga', 'Coffee', 'Art']},
    {'name': 'Kavya', 'age': 20, 'city': 'Delhi', 'bio': 'Living my best life 🌟', 'avatar': 'https://randomuser.me/api/portraits/women/7.jpg', 'interests': ['Fashion', 'Travel', 'Photography', 'Music']},
    {'name': 'Sneha', 'age': 24, 'city': 'Delhi', 'bio': 'Foodie capital explorer 🍜', 'avatar': 'https://randomuser.me/api/portraits/women/8.jpg', 'interests': ['Cooking', 'Travel', 'Fitness', 'Dance']},
    {'name': 'Divya', 'age': 23, 'city': 'Delhi', 'bio': 'Fashion designer in making 👗', 'avatar': 'https://randomuser.me/api/portraits/women/9.jpg', 'interests': ['Fashion', 'Art', 'Travel', 'Photography']},
    {'name': 'Pooja', 'age': 21, 'city': 'Delhi', 'bio': 'Shayari lover 💕', 'avatar': 'https://randomuser.me/api/portraits/women/10.jpg', 'interests': ['Reading', 'Music', 'Movies', 'Coffee']},
    // Bangalore
    {'name': 'Meera', 'age': 22, 'city': 'Bangalore', 'bio': 'Tech geek by day, dancer by night 💻', 'avatar': 'https://randomuser.me/api/portraits/women/11.jpg', 'interests': ['Tech', 'Dance', 'Gaming', 'Music']},
    {'name': 'Isha', 'age': 26, 'city': 'Bangalore', 'bio': 'Startup life ☕', 'avatar': 'https://randomuser.me/api/portraits/women/12.jpg', 'interests': ['Tech', 'Coffee', 'Travel', 'Photography']},
    {'name': 'Aditi', 'age': 23, 'city': 'Bangalore', 'bio': 'Coder & coffee addict 👩‍💻', 'avatar': 'https://randomuser.me/api/portraits/women/13.jpg', 'interests': ['Tech', 'Coffee', 'Gaming', 'Music']},
    {'name': 'Prachi', 'age': 21, 'city': 'Bangalore', 'bio': 'Garden city girl 🌿', 'avatar': 'https://randomuser.me/api/portraits/women/14.jpg', 'interests': ['Nature', 'Yoga', 'Travel', 'Photography']},
    {'name': 'Ritika', 'age': 24, 'city': 'Bangalore', 'bio': 'Music is my life 🎵', 'avatar': 'https://randomuser.me/api/portraits/women/15.jpg', 'interests': ['Music', 'Dance', 'Travel', 'Cooking']},
    // Pune
    {'name': 'Sakshi', 'age': 21, 'city': 'Pune', 'bio': 'Singer & night owl 🦉', 'avatar': 'https://randomuser.me/api/portraits/women/16.jpg', 'interests': ['Music', 'Movies', 'Cooking', 'Nature']},
    {'name': 'Simran', 'age': 20, 'city': 'Pune', 'bio': 'College vibes ✌️', 'avatar': 'https://randomuser.me/api/portraits/women/17.jpg', 'interests': ['Dance', 'Travel', 'Fitness', 'Music']},
    {'name': 'Mansi', 'age': 23, 'city': 'Pune', 'bio': 'Marathon runner 🏃‍♀️', 'avatar': 'https://randomuser.me/api/portraits/women/18.jpg', 'interests': ['Fitness', 'Travel', 'Photography', 'Nature']},
    {'name': 'Payal', 'age': 22, 'city': 'Pune', 'bio': 'Art is my therapy 🎨', 'avatar': 'https://randomuser.me/api/portraits/women/19.jpg', 'interests': ['Art', 'Photography', 'Coffee', 'Reading']},
    {'name': 'Sonali', 'age': 25, 'city': 'Pune', 'bio': 'Wanderlust soul 🌍', 'avatar': 'https://randomuser.me/api/portraits/women/20.jpg', 'interests': ['Travel', 'Photography', 'Nature', 'Yoga']},
    // Hyderabad
    {'name': 'Tanya', 'age': 21, 'city': 'Hyderabad', 'bio': 'Biryani lover 🍚', 'avatar': 'https://randomuser.me/api/portraits/women/21.jpg', 'interests': ['Cooking', 'Travel', 'Music', 'Movies']},
    {'name': 'Nisha', 'age': 23, 'city': 'Hyderabad', 'bio': 'Gym freak & foodie 💪', 'avatar': 'https://randomuser.me/api/portraits/women/22.jpg', 'interests': ['Fitness', 'Cooking', 'Travel', 'Sports']},
    {'name': 'Shreya', 'age': 22, 'city': 'Hyderabad', 'bio': 'IT professional by day 🖥️', 'avatar': 'https://randomuser.me/api/portraits/women/23.jpg', 'interests': ['Tech', 'Coffee', 'Travel', 'Dance']},
    {'name': 'Varsha', 'age': 24, 'city': 'Hyderabad', 'bio': 'Classical dance lover 💃', 'avatar': 'https://randomuser.me/api/portraits/women/24.jpg', 'interests': ['Dance', 'Art', 'Music', 'Yoga']},
    {'name': 'Lakshmi', 'age': 20, 'city': 'Hyderabad', 'bio': 'Book lover & chai addict ☕', 'avatar': 'https://randomuser.me/api/portraits/women/25.jpg', 'interests': ['Reading', 'Coffee', 'Travel', 'Photography']},
    // Chennai
    {'name': 'Deepa', 'age': 22, 'city': 'Chennai', 'bio': 'Filter coffee & Kollywood 🎬', 'avatar': 'https://randomuser.me/api/portraits/women/26.jpg', 'interests': ['Movies', 'Music', 'Cooking', 'Dance']},
    {'name': 'Kavitha', 'age': 24, 'city': 'Chennai', 'bio': 'Bharatanatyam dancer 🪷', 'avatar': 'https://randomuser.me/api/portraits/women/27.jpg', 'interests': ['Dance', 'Art', 'Yoga', 'Nature']},
    {'name': 'Janani', 'age': 21, 'city': 'Chennai', 'bio': 'Beach sunset chaser 🌅', 'avatar': 'https://randomuser.me/api/portraits/women/28.jpg', 'interests': ['Travel', 'Photography', 'Nature', 'Music']},
    {'name': 'Priyanka', 'age': 23, 'city': 'Chennai', 'bio': 'Carnatic music lover 🎶', 'avatar': 'https://randomuser.me/api/portraits/women/29.jpg', 'interests': ['Music', 'Dance', 'Art', 'Reading']},
    {'name': 'Swathi', 'age': 25, 'city': 'Chennai', 'bio': 'Silk saree enthusiast 👘', 'avatar': 'https://randomuser.me/api/portraits/women/30.jpg', 'interests': ['Fashion', 'Travel', 'Cooking', 'Photography']},
    // Kolkata
    {'name': 'Roshni', 'age': 22, 'city': 'Kolkata', 'bio': 'Rasgulla & adda lover 🍬', 'avatar': 'https://randomuser.me/api/portraits/women/31.jpg', 'interests': ['Cooking', 'Reading', 'Music', 'Art']},
    {'name': 'Suman', 'age': 21, 'city': 'Kolkata', 'bio': 'Durga Puja vibes 🪔', 'avatar': 'https://randomuser.me/api/portraits/women/32.jpg', 'interests': ['Dance', 'Music', 'Photography', 'Travel']},
    {'name': 'Ankita', 'age': 24, 'city': 'Kolkata', 'bio': 'Poetry & rain lover 🌧️', 'avatar': 'https://randomuser.me/api/portraits/women/33.jpg', 'interests': ['Reading', 'Art', 'Music', 'Coffee']},
    {'name': 'Mitali', 'age': 23, 'city': 'Kolkata', 'bio': 'Fish curry & football ⚽', 'avatar': 'https://randomuser.me/api/portraits/women/34.jpg', 'interests': ['Sports', 'Cooking', 'Travel', 'Music']},
    {'name': 'Pallavi', 'age': 20, 'city': 'Kolkata', 'bio': 'Art student 🎨', 'avatar': 'https://randomuser.me/api/portraits/women/35.jpg', 'interests': ['Art', 'Photography', 'Coffee', 'Travel']},
    // Jaipur
    {'name': 'Komal', 'age': 22, 'city': 'Jaipur', 'bio': 'Pink city princess 👸', 'avatar': 'https://randomuser.me/api/portraits/women/36.jpg', 'interests': ['Fashion', 'Travel', 'Photography', 'Dance']},
    {'name': 'Garima', 'age': 23, 'city': 'Jaipur', 'bio': 'Rajasthani food lover 🍛', 'avatar': 'https://randomuser.me/api/portraits/women/37.jpg', 'interests': ['Cooking', 'Travel', 'Music', 'Art']},
    {'name': 'Jyoti', 'age': 21, 'city': 'Jaipur', 'bio': 'Fort explorer 🏰', 'avatar': 'https://randomuser.me/api/portraits/women/38.jpg', 'interests': ['Travel', 'Photography', 'History', 'Art']},
    {'name': 'Nandini', 'age': 24, 'city': 'Jaipur', 'bio': 'Mehndi artist 🌸', 'avatar': 'https://randomuser.me/api/portraits/women/39.jpg', 'interests': ['Art', 'Fashion', 'Dance', 'Photography']},
    {'name': 'Preeti', 'age': 20, 'city': 'Jaipur', 'bio': 'Ghoomar dancer 💃', 'avatar': 'https://randomuser.me/api/portraits/women/40.jpg', 'interests': ['Dance', 'Music', 'Travel', 'Cooking']},
    // Ahmedabad
    {'name': 'Disha', 'age': 22, 'city': 'Ahmedabad', 'bio': 'Dhokla & garba lover 🕺', 'avatar': 'https://randomuser.me/api/portraits/women/41.jpg', 'interests': ['Dance', 'Cooking', 'Travel', 'Music']},
    {'name': 'Hetal', 'age': 23, 'city': 'Ahmedabad', 'bio': 'Business minded girl 💼', 'avatar': 'https://randomuser.me/api/portraits/women/42.jpg', 'interests': ['Tech', 'Travel', 'Fitness', 'Coffee']},
    {'name': 'Foram', 'age': 21, 'city': 'Ahmedabad', 'bio': 'Textile design student 🧵', 'avatar': 'https://randomuser.me/api/portraits/women/43.jpg', 'interests': ['Fashion', 'Art', 'Photography', 'Travel']},
    {'name': 'Zeel', 'age': 24, 'city': 'Ahmedabad', 'bio': 'Navratri queen 🪩', 'avatar': 'https://randomuser.me/api/portraits/women/44.jpg', 'interests': ['Dance', 'Music', 'Fashion', 'Cooking']},
    {'name': 'Bhavya', 'age': 20, 'city': 'Ahmedabad', 'bio': 'Food blogger 🍽️', 'avatar': 'https://randomuser.me/api/portraits/women/45.jpg', 'interests': ['Cooking', 'Photography', 'Travel', 'Coffee']},
    // Chandigarh
    {'name': 'Simran', 'age': 22, 'city': 'Chandigarh', 'bio': 'Punjabi kudi with big dreams 🌟', 'avatar': 'https://randomuser.me/api/portraits/women/46.jpg', 'interests': ['Dance', 'Travel', 'Fitness', 'Music']},
    {'name': 'Harpreet', 'age': 23, 'city': 'Ch Chandigarh', 'bio': 'Butter chicken lover 🍗', 'avatar': 'https://randomuser.me/api/portraits/women/47.jpg', 'interests': ['Cooking', 'Travel', 'Music', 'Dance']},
    {'name': 'Gurleen', 'age': 21, 'city': 'Chandigarh', 'bio': 'Sikhni from Chandigarh ✨', 'avatar': 'https://randomuser.me/api/portraits/women/48.jpg', 'interests': ['Fashion', 'Dance', 'Travel', 'Photography']},
    {'name': 'Manpreet', 'age': 24, 'city': 'Chandigarh', 'bio': 'Rock garden visitor 🪨', 'avatar': 'https://randomuser.me/api/portraits/women/49.jpg', 'interests': ['Travel', 'Nature', 'Photography', 'Yoga']},
    {'name': 'Jasmine', 'age': 20, 'city': 'Chandigarh', 'bio': 'Bhangra queen 💃', 'avatar': 'https://randomuser.me/api/portraits/women/50.jpg', 'interests': ['Dance', 'Music', 'Fitness', 'Travel']},
    // Lucknow
    {'name': 'Fatima', 'age': 22, 'city': 'Lucknow', 'bio': 'Tehzeeb & biryani 🍚', 'avatar': 'https://randomuser.me/api/portraits/women/51.jpg', 'interests': ['Cooking', 'Reading', 'Music', 'Art']},
    {'name': 'Zara', 'age': 23, 'city': 'Lucknow', 'bio': 'Chikankari lover 🪡', 'avatar': 'https://randomuser.me/api/portraits/women/52.jpg', 'interests': ['Fashion', 'Art', 'Travel', 'Photography']},
    {'name': 'Ayesha', 'age': 21, 'city': 'Lucknow', 'bio': 'Nawabi vibes 👑', 'avatar': 'https://randomuser.me/api/portraits/women/53.jpg', 'interests': ['Travel', 'History', 'Cooking', 'Music']},
    {'name': 'Saba', 'age': 24, 'city': 'Lucknow', 'bio': 'Poetry lover 📝', 'avatar': 'https://randomuser.me/api/portraits/women/54.jpg', 'interests': ['Reading', 'Art', 'Coffee', 'Music']},
    {'name': 'Rukhsar', 'age': 20, 'city': 'Lucknow', 'bio': 'Kebab connoisseur 🍢', 'avatar': 'https://randomuser.me/api/portraits/women/55.jpg', 'interests': ['Cooking', 'Travel', 'Photography', 'Dance']},
    // Noida
    {'name': 'Shivani', 'age': 22, 'city': 'Noida', 'bio': 'Mall rat 🛍️', 'avatar': 'https://randomuser.me/api/portraits/women/56.jpg', 'interests': ['Fashion', 'Travel', 'Coffee', 'Photography']},
    {'name': 'Monika', 'age': 23, 'city': 'Noida', 'bio': 'Gym is my temple 🏋️', 'avatar': 'https://randomuser.me/api/portraits/women/57.jpg', 'interests': ['Fitness', 'Travel', 'Cooking', 'Music']},
    {'name': 'Pooja', 'age': 25, 'city': 'Noida', 'bio': 'Startup hustle 💪', 'avatar': 'https://randomuser.me/api/portraits/women/58.jpg', 'interests': ['Tech', 'Coffee', 'Travel', 'Reading']},
    {'name': 'Richa', 'age': 21, 'city': 'Noida', 'bio': 'Movie buff 🎬', 'avatar': 'https://randomuser.me/api/portraits/women/59.jpg', 'interests': ['Movies', 'Music', 'Travel', 'Cooking']},
    {'name': 'Nupur', 'age': 24, 'city': 'Noida', 'bio': 'Bookworm & chai lover ☕', 'avatar': 'https://randomuser.me/api/portraits/women/60.jpg', 'interests': ['Reading', 'Coffee', 'Travel', 'Art']},
    // Indore
    {'name': 'Khushi', 'age': 22, 'city': 'Indore', 'bio': 'Poha & jalebi lover 🍩', 'avatar': 'https://randomuser.me/api/portraits/women/61.jpg', 'interests': ['Cooking', 'Travel', 'Music', 'Dance']},
    {'name': 'Muskan', 'age': 21, 'city': 'Indore', 'bio': 'Street food explorer 🍢', 'avatar': 'https://randomuser.me/api/portraits/women/62.jpg', 'interests': ['Cooking', 'Photography', 'Travel', 'Music']},
    {'name': 'Twinkle', 'age': 23, 'city': 'Indore', 'bio': 'Sarafa bazaar lover 🌙', 'avatar': 'https://randomuser.me/api/portraits/women/63.jpg', 'interests': ['Cooking', 'Travel', 'Fashion', 'Photography']},
    {'name': 'Chhavi', 'age': 20, 'city': 'Indore', 'bio': 'Dance is my oxygen 💃', 'avatar': 'https://randomuser.me/api/portraits/women/64.jpg', 'interests': ['Dance', 'Music', 'Fitness', 'Travel']},
    {'name': 'Anju', 'age': 24, 'city': 'Indore', 'bio': 'Rajwada vibes 🏛️', 'avatar': 'https://randomuser.me/api/portraits/women/65.jpg', 'interests': ['Travel', 'History', 'Photography', 'Art']},
    // Bhopal
    {'name': 'Kajal', 'age': 22, 'city': 'Bhopal', 'bio': 'Lake city girl 🌊', 'avatar': 'https://randomuser.me/api/portraits/women/66.jpg', 'interests': ['Travel', 'Photography', 'Nature', 'Yoga']},
    {'name': 'Pinky', 'age': 23, 'city': 'Bhopal', 'bio': 'Bhutta lover in rains 🌽', 'avatar': 'https://randomuser.me/api/portraits/women/67.jpg', 'interests': ['Cooking', 'Travel', 'Music', 'Nature']},
    {'name': 'Seema', 'age': 21, 'city': 'Bhopal', 'bio': 'Van Vihar visitor 🦌', 'avatar': 'https://randomuser.me/api/portraits/women/68.jpg', 'interests': ['Nature', 'Travel', 'Photography', 'Yoga']},
    {'name': 'Rekha', 'age': 24, 'city': 'Bhopal', 'bio': 'Sanchi stupa lover 🏛️', 'avatar': 'https://randomuser.me/api/portraits/women/69.jpg', 'interests': ['Travel', 'History', 'Art', 'Photography']},
    {'name': 'Sunita', 'age': 20, 'city': 'Bhopal', 'bio': 'Simple girl with big dreams ✨', 'avatar': 'https://randomuser.me/api/portraits/women/70.jpg', 'interests': ['Reading', 'Music', 'Travel', 'Coffee']},
    // Amritsar
    {'name': 'Harman', 'age': 22, 'city': 'Amritsar', 'bio': 'Golden Temple lover 🙏', 'avatar': 'https://randomuser.me/api/portraits/women/71.jpg', 'interests': ['Travel', 'Photography', 'Cooking', 'Music']},
    {'name': 'Navjot', 'age': 23, 'city': 'Amritsar', 'bio': 'Amritsari kulcha fan 🫓', 'avatar': 'https://randomuser.me/api/portraits/women/72.jpg', 'interests': ['Cooking', 'Travel', 'Dance', 'Music']},
    {'name': 'Prabhjot', 'age': 21, 'city': 'Amritsar', 'bio': 'Wagah border visitor 🇮🇳', 'avatar': 'https://randomuser.me/api/portraits/women/73.jpg', 'interests': ['Travel', 'Photography', 'History', 'Fitness']},
    {'name': 'Gurpreet', 'age': 24, 'city': 'Amritsar', 'bio': 'Langar seva lover 🙏', 'avatar': 'https://randomuser.me/api/portraits/women/74.jpg', 'interests': ['Travel', 'Cooking', 'Music', 'Yoga']},
    {'name': 'Amrit', 'age': 20, 'city': 'Amritsar', 'bio': 'Punjabi pop lover 🎵', 'avatar': 'https://randomuser.me/api/portraits/women/75.jpg', 'interests': ['Music', 'Dance', 'Travel', 'Fitness']},
    // Nagpur
    {'name': 'Durga', 'age': 22, 'city': 'Nagpur', 'bio': 'Orange city girl 🍊', 'avatar': 'https://randomuser.me/api/portraits/women/76.jpg', 'interests': ['Travel', 'Cooking', 'Music', 'Photography']},
    {'name': 'Vaishnavi', 'age': 23, 'city': 'Nagpur', 'bio': 'Samosa lover 🥟', 'avatar': 'https://randomuser.me/api/portraits/women/77.jpg', 'interests': ['Cooking', 'Travel', 'Dance', 'Music']},
    {'name': 'Sai', 'age': 21, 'city': 'Nagpur', 'bio': 'Ambazari lake lover 🌅', 'avatar': 'https://randomuser.me/api/portraits/women/78.jpg', 'interests': ['Nature', 'Travel', 'Photography', 'Yoga']},
    {'name': 'Trupti', 'age': 24, 'city': 'Nagpur', 'bio': 'Vidarbha food explorer 🍛', 'avatar': 'https://randomuser.me/api/portraits/women/79.jpg', 'interests': ['Cooking', 'Travel', 'Photography', 'Art']},
    {'name': 'Aarti', 'age': 20, 'city': 'Nagpur', 'bio': 'Tarri poha lover 🍚', 'avatar': 'https://randomuser.me/api/portraits/women/80.jpg', 'interests': ['Cooking', 'Music', 'Travel', 'Dance']},
    // Visakhapatnam
    {'name': 'Lakshmi', 'age': 22, 'city': 'Vizag', 'bio': 'Beach baby 🏖️', 'avatar': 'https://randomuser.me/api/portraits/women/81.jpg', 'interests': ['Travel', 'Photography', 'Nature', 'Dance']},
    {'name': 'Satya', 'age': 23, 'city': 'Vizag', 'bio': 'Araku valley lover ⛰️', 'avatar': 'https://randomuser.me/api/portraits/women/82.jpg', 'interests': ['Travel', 'Nature', 'Photography', 'Cooking']},
    {'name': 'Siri', 'age': 21, 'city': 'Vizag', 'bio': 'Submarine museum visitor 🚢', 'avatar': 'https://randomuser.me/api/portraits/women/83.jpg', 'interests': ['Travel', 'History', 'Photography', 'Art']},
    {'name': 'Harika', 'age': 24, 'city': 'Vizag', 'bio': 'Kailasagiri hill lover ⛰️', 'avatar': 'https://randomuser.me/api/portraits/women/84.jpg', 'interests': ['Nature', 'Travel', 'Yoga', 'Photography']},
    {'name': 'Bhavani', 'age': 20, 'city': 'Vizag', 'bio': 'Rushikonda surfer 🏄', 'avatar': 'https://randomuser.me/api/portraits/women/85.jpg', 'interests': ['Sports', 'Travel', 'Nature', 'Fitness']},
    // Kochi
    {'name': 'Mariya', 'age': 22, 'city': 'Kochi', 'bio': 'Backwater lover 🚣', 'avatar': 'https://randomuser.me/api/portraits/women/86.jpg', 'interests': ['Travel', 'Nature', 'Photography', 'Cooking']},
    {'name': 'Anu', 'age': 23, 'city': 'Kochi', 'bio': 'Kathakali admirer 💃', 'avatar': 'https://randomuser.me/api/portraits/women/87.jpg', 'interests': ['Dance', 'Art', 'Music', 'Travel']},
    {'name': 'Nimmy', 'age': 21, 'city': 'Kochi', 'bio': 'Fish curry lover 🐟', 'avatar': 'https://randomuser.me/api/portraits/women/88.jpg', 'interests': ['Cooking', 'Travel', 'Nature', 'Photography']},
    {'name': 'Sneha', 'age': 24, 'city': 'Kochi', 'bio': 'Fort Kochi explorer 🏛️', 'avatar': 'https://randomuser.me/api/portraits/women/89.jpg', 'interests': ['Travel', 'History', 'Photography', 'Art']},
    {'name': 'Divya', 'age': 20, 'city': 'Kochi', 'bio': 'Munnar tea lover 🍵', 'avatar': 'https://randomuser.me/api/portraits/women/90.jpg', 'interests': ['Travel', 'Nature', 'Coffee', 'Photography']},
    // Guwahati
    {'name': 'Juri', 'age': 22, 'city': 'Guwahati', 'bio': 'Brahmaputra lover 🌊', 'avatar': 'https://randomuser.me/api/portraits/women/91.jpg', 'interests': ['Travel', 'Nature', 'Photography', 'Music']},
    {'name': 'Mandira', 'age': 23, 'city': 'Guwahati', 'bio': 'Assam tea garden girl 🍵', 'avatar': 'https://randomuser.me/api/portraits/women/92.jpg', 'interests': ['Travel', 'Nature', 'Cooking', 'Photography']},
    {'name': 'Bornali', 'age': 21, 'city': 'Guwahati', 'bio': 'Bihu dancer 💃', 'avatar': 'https://randomuser.me/api/portraits/women/93.jpg', 'interests': ['Dance', 'Music', 'Travel', 'Cooking']},
    {'name': 'Rima', 'age': 24, 'city': 'Guwahati', 'bio': 'Kamakhya temple devotee 🙏', 'avatar': 'https://randomuser.me/api/portraits/women/94.jpg', 'interests': ['Travel', 'Photography', 'Yoga', 'Nature']},
    {'name': 'Dipika', 'age': 20, 'city': 'Guwahati', 'bio': 'Northeast explorer 🏔️', 'avatar': 'https://randomuser.me/api/portraits/women/95.jpg', 'interests': ['Travel', 'Nature', 'Photography', 'Fitness']},
    // Chandigarh (extra)
    {'name': 'Arshpreet', 'age': 22, 'city': 'Chandigarh', 'bio': 'Sector 17 shopper 🛍️', 'avatar': 'https://randomuser.me/api/portraits/women/96.jpg', 'interests': ['Fashion', 'Travel', 'Coffee', 'Photography']},
    {'name': 'Lovepreet', 'age': 23, 'city': 'Chandigarh', 'bio': 'Sukhna lake lover 🌅', 'avatar': 'https://randomuser.me/api/portraits/women/97.jpg', 'interests': ['Nature', 'Travel', 'Photography', 'Yoga']},
    {'name': 'Gagandeep', 'age': 21, 'city': 'Chandigarh', 'bio': 'Chole bhature lover 🍛', 'avatar': 'https://randomuser.me/api/portraits/women/98.jpg', 'interests': ['Cooking', 'Travel', 'Dance', 'Music']},
    {'name': 'Manjot', 'age': 24, 'city': 'Chandigarh', 'bio': 'Rose garden visitor 🌹', 'avatar': 'https://randomuser.me/api/portraits/women/99.jpg', 'interests': ['Nature', 'Travel', 'Photography', 'Art']},
    {'name': 'Prabhnoor', 'age': 20, 'city': 'Chandigarh', 'bio': 'Punjabi mundi 🌟', 'avatar': 'https://randomuser.me/api/portraits/women/100.jpg', 'interests': ['Dance', 'Music', 'Fitness', 'Travel']},
    // Extra diverse
    {'name': 'Kiara', 'age': 22, 'city': 'Goa', 'bio': 'Beach party queen 🎉', 'avatar': 'https://randomuser.me/api/portraits/women/41.jpg', 'interests': ['Travel', 'Dance', 'Music', 'Photography']},
    {'name': 'Alia', 'age': 23, 'city': 'Shimla', 'bio': 'Mountain child 🏔️', 'avatar': 'https://randomuser.me/api/portraits/women/42.jpg', 'interests': ['Travel', 'Nature', 'Photography', 'Yoga']},
    {'name': 'Sara', 'age': 21, 'city': 'Udaipur', 'bio': 'Lake city princess 👑', 'avatar': 'https://randomuser.me/api/portraits/women/43.jpg', 'interests': ['Travel', 'History', 'Photography', 'Art']},
    {'name': 'Myra', 'age': 24, 'city': 'Manali', 'bio': 'Snow lover ❄️', 'avatar': 'https://randomuser.me/api/portraits/women/44.jpg', 'interests': ['Travel', 'Nature', 'Fitness', 'Photography']},
    {'name': 'Zoya', 'age': 20, 'city': 'Darjeeling', 'bio': 'Tea & mountains 🍵', 'avatar': 'https://randomuser.me/api/portraits/women/45.jpg', 'interests': ['Travel', 'Nature', 'Coffee', 'Photography']},
  ];

  // ─── Chat Responses (more scripts for variety) ──────────────
  static final List<List<String>> _chatScripts = [
    // Script 1 — Friendly
    [
      "Heyy! How are you? 😊",
      "Oh nice! Where are you from?",
      "That's cool! I love that place",
      "Haha you're funny 😂",
      "What do you do for fun?",
      "Oh that's interesting!",
      "I love music too! What kind?",
      "Nice taste 🎵",
      "Do you travel a lot?",
      "We should totally meet sometime 😄",
    ],
    // Script 2 — Flirty
    [
      "Hey handsome 😘",
      "You look cute!",
      "Haha really? Tell me more",
      "I like your vibe ✨",
      "What's your favorite movie?",
      "Oh I love that one!",
      "You have good taste 😊",
      "Where do you hang out usually?",
      "Maybe we can go together sometime",
      "I'd love that 💕",
    ],
    // Script 3 — Curious
    [
      "Hi! 👋",
      "So what brings you here?",
      "Same here! Looking for new people",
      "That's awesome! What's your passion?",
      "Wow that's so cool!",
      "I'm into music and art",
      "Do you play any instruments?",
      "No way! I play guitar too 🎸",
      "We should jam together sometime 😄",
      "That would be so fun!",
    ],
    // Script 4 — Chill
    [
      "Hey! What's up?",
      "Not much, just chilling 😌",
      "Same here lol",
      "What's your go-to comfort food?",
      "Ooh good choice! I love pizza too 🍕",
      "Movie or series?",
      "Nice! What are you watching these days?",
      "I've been binging that too!",
      "No spoilers please 😂",
      "Haha my lips are sealed 🤐",
    ],
    // Script 5 — Energetic
    [
      "HEYY!! 🎉",
      "How's your day going?",
      "Mine's been amazing!",
      "I went to this cool cafe today",
      "You should totally check it out!",
      "The coffee was ☕🤌",
      "Do you like coffee?",
      "We should go together sometime!",
      "I know all the best spots 😎",
      "It's a date then! 😉",
    ],
    // Script 6 — Hindi mix
    [
      "Hii! Kaise ho? 😊",
      "Main bhi achhi hoon!",
      "Tum kahan se ho?",
      "Oh wow, mujhe bhi wahan jaana hai!",
      "Tumhari smile bahut pyaari hai 🥰",
      "Sachchi? Thank you!",
      "Kya karte ho free time mein?",
      "Oh nice! Mujhe bhi pasand hai",
      "Kabhi milte hain coffee pe ☕",
      "Haan bilkul! Pakka 💕",
    ],
    // Script 7 — Sweet
    [
      "Hey there! 🌸",
      "You seem really nice!",
      "I love your profile btw",
      "Haha thank you!",
      "What kind of music do you listen to?",
      "Oh same! I love that artist",
      "We have so much in common!",
      "I know right! It's destiny 😄",
      "Tell me something about yourself",
      "That's so cool! I'm impressed ✨",
    ],
    // Script 8 — Playful
    [
      "Knock knock! 😂",
      "Haha who's there?",
      "Your future bestie! 👯",
      "Omg that's so cute 😂",
      "I'm bored, entertain me!",
      "Haha challenge accepted!",
      "You're actually funny!",
      "I know right? 😎",
      "Let's play 20 questions!",
      "Okay you go first! 🎯",
    ],
  ];

  // ─── Get a random bot profile ───────────────────────────────
  static Map<String, dynamic> getRandomBot({String genderFilter = 'All'}) {
    final bot = Map<String, dynamic>.from(
      _botProfiles[_random.nextInt(_botProfiles.length)],
    );
    bot['uid'] = 'bot_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
    bot['isBot'] = true;
    return bot;
  }

  // ─── Get a random chat script ───────────────────────────────
  static List<String> getRandomChatScript() {
    return List<String>.from(
      _chatScripts[_random.nextInt(_chatScripts.length)],
    );
  }

  // ─── Simulate typing delay ──────────────────────────────────
  static Duration getTypingDelay() {
    return Duration(seconds: 2 + _random.nextInt(4));
  }

  // ─── Simulate call duration before "disconnect" ─────────────
  static Duration getCallDuration() {
    return Duration(seconds: 20 + _random.nextInt(40));
  }

  // ─── Get "next bot" after skip ──────────────────────────────
  static Map<String, dynamic> getNextBot({
    required String excludeName,
    String genderFilter = 'All',
  }) {
    final available = _botProfiles.where((b) => b['name'] != excludeName).toList();
    final bot = Map<String, dynamic>.from(
      available[_random.nextInt(available.length)],
    );
    bot['uid'] = 'bot_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
    bot['isBot'] = true;
    return bot;
  }

  // ─── Simulate "online" users count ──────────────────────────
  static int getSimulatedOnlineCount() {
    return 50 + _random.nextInt(150);
  }

  // ─── Free video URLs for bot video calls ───────────────────
  // These are short portrait videos of women from free CDN sources
  static final List<String> _botVideoUrls = [
    'https://cdn.pixabay.com/video/2024/02/23/201483-915915398_large.mp4',
    'https://cdn.pixabay.com/video/2020/07/30/45349-446786598_large.mp4',
    'https://cdn.pixabay.com/video/2021/04/10/70502-536538498_large.mp4',
    'https://cdn.pixabay.com/video/2023/10/17/185454-875602692_large.mp4',
    'https://cdn.pixabay.com/video/2020/05/25/40037-424930959_large.mp4',
    'https://cdn.pixabay.com/video/2024/01/11/196042-900984785_large.mp4',
    'https://cdn.pixabay.com/video/2022/08/02/126654-735696783_large.mp4',
    'https://cdn.pixabay.com/video/2023/03/22/155481-811455498_large.mp4',
    'https://cdn.pixabay.com/video/2021/08/10/84704-587403358_large.mp4',
    'https://cdn.pixabay.com/video/2020/10/15/52805-471519676_large.mp4',
    'https://cdn.pixabay.com/video/2023/06/12/166504-836689036_large.mp4',
    'https://cdn.pixabay.com/video/2022/03/28/112367-693498576_large.mp4',
    'https://cdn.pixabay.com/video/2024/03/16/204469-925555148_large.mp4',
    'https://cdn.pixabay.com/video/2021/02/14/64982-511752925_large.mp4',
    'https://cdn.pixabay.com/video/2020/09/03/49034-456885275_large.mp4',
    'https://cdn.pixabay.com/video/2023/11/28/191096-887988032_large.mp4',
    'https://cdn.pixabay.com/video/2022/05/26/117998-715478695_large.mp4',
    'https://cdn.pixabay.com/video/2023/07/04/169744-844739855_large.mp4',
    'https://cdn.pixabay.com/video/2021/06/28/79031-568823698_large.mp4',
    'https://cdn.pixabay.com/video/2020/11/28/57523-485296695_large.mp4',
  ];

  static String getRandomVideoUrl() {
    return _botVideoUrls[_random.nextInt(_botVideoUrls.length)];
  }

  static String getVideoUrlForIndex(int index) {
    return _botVideoUrls[index % _botVideoUrls.length];
  }

  // ─── Bot reaction messages (during call) ────────────────────
  static final List<String> _reactions = [
    "😂", "😊", "❤️", "😍", "🥰", "✨", "💕", "😘", "🙈", "🎉",
    "🔥", "💯", "😘", "🥰", "💖",
  ];

  static String getRandomReaction() {
    return _reactions[_random.nextInt(_reactions.length)];
  }

  // ─── Get bot by index (for home screen display) ─────────────
  static Map<String, dynamic> getBotByIndex(int index) {
    return _botProfiles[index % _botProfiles.length];
  }

  // ─── Get total bot count ────────────────────────────────────
  static int get botCount => _botProfiles.length;
}
