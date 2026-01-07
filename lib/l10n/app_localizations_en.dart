// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FootHub';

  @override
  String get appTagline => 'FootHub';

  @override
  String get home => 'Home';

  @override
  String get schedule => 'Matches';

  @override
  String get standings => 'Ranks';

  @override
  String get leagues => 'Leagues';

  @override
  String get community => 'Social';

  @override
  String get favorites => 'Favs';

  @override
  String get profile => 'Profile';

  @override
  String hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get footballFan => 'Football Fan';

  @override
  String get record => 'Record';

  @override
  String get attendanceRecord => 'Match Record';

  @override
  String get myAttendanceRecord => 'My Match Records';

  @override
  String get myAttendanceDiary => 'My Match Diary';

  @override
  String get attendanceDiary => 'Match Diary';

  @override
  String get myRecords => 'My attendance records';

  @override
  String get viewAll => 'View All';

  @override
  String get manage => 'Manage';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get selectYear => 'Select Year';

  @override
  String get selectMonth => 'Select Month';

  @override
  String get selectDay => 'Select Day';

  @override
  String get yearSuffix => '';

  @override
  String get monthSuffix => '';

  @override
  String get daySuffix => '';

  @override
  String get save => 'Save';

  @override
  String get select => 'Select';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get more => 'More';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get totalMatches => 'Total';

  @override
  String get matchCount => '';

  @override
  String get win => 'Win';

  @override
  String get winShort => 'W';

  @override
  String get draw => 'Draw';

  @override
  String get drawShort => 'D';

  @override
  String get loss => 'Loss';

  @override
  String get lossShort => 'L';

  @override
  String get winRate => 'Win Rate';

  @override
  String get stadium => 'Venue';

  @override
  String get stadiumCount => '';

  @override
  String get times => 'times';

  @override
  String get cannotLoadStats => 'Could not load statistics';

  @override
  String get cannotLoadSchedule => 'Unable to load schedule';

  @override
  String get cannotLoadRecords => 'Unable to load records';

  @override
  String get cannotLoadTeamList => 'Unable to load team list';

  @override
  String get loadFailed => 'Load failed';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get live => 'Live Matches';

  @override
  String liveMatchCount(int count) {
    return '$count matches';
  }

  @override
  String get autoRefreshEvery30Sec => 'Auto-refresh every 30 seconds';

  @override
  String get noLiveMatches => 'No live matches';

  @override
  String get firstHalf => '1st Half';

  @override
  String get secondHalf => '2nd Half';

  @override
  String get halfTime => 'Half Time';

  @override
  String get extraTime => 'Extra Time';

  @override
  String get penalties => 'Penalties';

  @override
  String get finished => 'FT';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get favoriteTeamSchedule => 'Favorite Schedule';

  @override
  String get addFavoriteTeam => 'Add your favorite team';

  @override
  String get addFavoriteTeamDesc => 'Add a team to see upcoming matches';

  @override
  String get recentRecords => 'Recent Records';

  @override
  String get firstRecordPrompt => 'Record your first match';

  @override
  String get firstRecordDesc => 'Capture special moments at the stadium';

  @override
  String get nextMatch => 'Next Match';

  @override
  String get noScheduledMatches => 'No scheduled matches';

  @override
  String get recent5Matches => 'Last 5 matches';

  @override
  String get selectNationalTeam => 'Select your national team to support';

  @override
  String get selectNationalTeamPrompt => 'Choose a national team to support';

  @override
  String get worldCupParticipants => '2026 World Cup Participants';

  @override
  String get searchCountry => 'Search country...';

  @override
  String get matchSchedule => 'Schedule';

  @override
  String get today => 'Today';

  @override
  String get monthly => 'Monthly';

  @override
  String get twoWeeks => '2 Weeks';

  @override
  String get weekly => 'Weekly';

  @override
  String get major => 'Major';

  @override
  String get all => 'All';

  @override
  String get recordAttendance => 'Record Attendance';

  @override
  String get attendanceComplete => 'Attended';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get matchNotification => 'Match Notification';

  @override
  String get kickoffNotification => 'Kickoff Alert';

  @override
  String get kickoffNotificationDesc => '30 min before kickoff';

  @override
  String get lineupNotification => 'Lineup Alert';

  @override
  String get lineupNotificationDesc => 'When lineup released';

  @override
  String get resultNotification => 'Result Alert';

  @override
  String get resultNotificationDesc => 'When match ends';

  @override
  String get notificationOff => 'Turn Off';

  @override
  String get notificationSet => 'Notification set';

  @override
  String get notificationRemoved => 'Notification removed';

  @override
  String get team => 'Team';

  @override
  String get teams => 'Teams';

  @override
  String get player => 'Player';

  @override
  String get players => 'Players';

  @override
  String get addTeam => 'Add Team';

  @override
  String get addPlayer => 'Add Player';

  @override
  String get searchTeam => 'Search team...';

  @override
  String get searchPlayer => 'Search player...';

  @override
  String get removeFavorite => 'Remove';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get unfollowTeam => 'Unfollow Team';

  @override
  String unfollowTeamConfirm(String name) {
    return 'Remove $name from favorites?';
  }

  @override
  String get unfollowPlayer => 'Unfollow Player';

  @override
  String unfollowPlayerConfirm(String name) {
    return 'Remove $name from favorites?';
  }

  @override
  String get selectLeagueOrSearch => 'Select a league or search for a team';

  @override
  String get teamNotFound => 'Team not found';

  @override
  String get playerNotFound => 'No players found';

  @override
  String get searchTeamFirst => 'Search for a team';

  @override
  String get filterPlayers => 'Filter by player name...';

  @override
  String get searchTeamToAddPlayer => 'Search for a team to add players';

  @override
  String get national => 'National';

  @override
  String get addFavoriteTeamPrompt => 'Add your favorite team';

  @override
  String get addFavoritePlayerPrompt => 'Add favorite player';

  @override
  String get list => 'List';

  @override
  String get calendar => 'Calendar';

  @override
  String get stats => 'Stats';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String get deleteRecordConfirm =>
      'Are you sure you want to delete this record?';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String noRecordOnDate(String date) {
    return 'No records on $date';
  }

  @override
  String get selectDate => 'Select a date';

  @override
  String get noRecordsYet => 'No records yet';

  @override
  String get leagueStats => 'Stats by League';

  @override
  String get stadiumVisits => 'Stadium Visits';

  @override
  String get visitedStadiums => 'Visited Stadiums';

  @override
  String get user => 'User';

  @override
  String get activeMember => 'Active Member';

  @override
  String get loginPromptTitle => 'Sign in to get started';

  @override
  String get loginPromptSubtitle =>
      'Save and manage your match attendance records';

  @override
  String get leagueStandings => 'League Standings';

  @override
  String get checkLeagueStandings => 'Check league standings';

  @override
  String get upcomingMatches => 'Upcoming Matches';

  @override
  String get matchAlertsPush => 'Match alerts, Push notifications';

  @override
  String get timezoneSettings => 'Timezone Settings';

  @override
  String get matchTimeDisplay => 'Match time display';

  @override
  String get communityTitle => 'Community';

  @override
  String get communityDesc => 'Match reviews, Info sharing';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get faqContact => 'FAQ, Contact Us';

  @override
  String get logout => 'Log Out';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get languageSettings => 'Language';

  @override
  String get korean => '한국어';

  @override
  String get english => 'English';

  @override
  String get systemDefault => 'System Default';

  @override
  String appVersion(String version) {
    return 'v$version';
  }

  @override
  String get liveMatches => 'Live Matches';

  @override
  String updatedSecondsAgo(int seconds) {
    return 'Updated ${seconds}s ago';
  }

  @override
  String updatedMinutesAgo(int minutes) {
    return 'Updated ${minutes}m ago';
  }

  @override
  String get autoRefresh30Sec => 'Auto-refresh every 30s';

  @override
  String get noLiveMatchesTitle => 'No live matches';

  @override
  String get noLiveMatchesDesc => 'Check back when matches start';

  @override
  String get breakPrep => 'Break';

  @override
  String firstHalfMinutes(int minutes) {
    return '1H $minutes\'';
  }

  @override
  String secondHalfMinutes(int minutes) {
    return '2H $minutes\'';
  }

  @override
  String get searchLeague => 'Search...';

  @override
  String get noSearchResults => 'No results';

  @override
  String get searchError => 'Search error';

  @override
  String get top5Leagues => 'Top 5';

  @override
  String get euroClubComps => 'Europe';

  @override
  String get nationalComps => 'National';

  @override
  String get otherLeagues => 'Others';

  @override
  String get myLocalLeague => 'My Local League';

  @override
  String get cannotLoadLeagues => 'Failed to load';

  @override
  String get byCountry => 'Countries';

  @override
  String get rank => 'Rank';

  @override
  String get goals => 'Goals';

  @override
  String get assists => 'Assists';

  @override
  String get played => 'P';

  @override
  String get won => 'W';

  @override
  String get drawn => 'D';

  @override
  String get lost => 'L';

  @override
  String get gf => 'GF';

  @override
  String get ga => 'GA';

  @override
  String get gd => 'GD';

  @override
  String get pts => 'Pts';

  @override
  String get appearances => 'Apps';

  @override
  String get noStandingsInfo => 'No standings';

  @override
  String get cannotLoadStandings => 'Failed to load';

  @override
  String get noGoalRankInfo => 'No data';

  @override
  String get noAssistRankInfo => 'No data';

  @override
  String get noLeagueStats => 'No league statistics available';

  @override
  String get recentForm => 'Form';

  @override
  String get last5Games => 'Last 5';

  @override
  String get homeAwayStrength => 'Home/Away';

  @override
  String get homeStrength => 'Home';

  @override
  String get awayStrength => 'Away';

  @override
  String get bottomAnalysis => 'Bottom Analysis';

  @override
  String get mostLosses => 'Most Losses';

  @override
  String get mostConceded => 'Most Conceded';

  @override
  String get leagueOverview => 'League Overview';

  @override
  String get totalGoals => 'Total Goals';

  @override
  String get goalsPerGame => 'Goals/Game';

  @override
  String get homeWins => 'Home Wins';

  @override
  String get awayWins => 'Away Wins';

  @override
  String get homeWin => 'Home W';

  @override
  String get awayWin => 'Away W';

  @override
  String nGames(int count) {
    return '${count}G';
  }

  @override
  String get teamRanking => 'Teams';

  @override
  String get mostGoals => 'Top Scorer';

  @override
  String get mostConcededGoals => 'Most GA';

  @override
  String get mostWins => 'Most Wins';

  @override
  String get mostDraws => 'Most Draws';

  @override
  String nGoals(int count) {
    return '$count goals';
  }

  @override
  String nWins(int count) {
    return '${count}W';
  }

  @override
  String nDraws(int count) {
    return '${count}D';
  }

  @override
  String nLosses(int count) {
    return '${count}L';
  }

  @override
  String nConceded(int count) {
    return '${count}GA';
  }

  @override
  String get goalAnalysis => 'Goals';

  @override
  String get homeGoals => 'Home Goals';

  @override
  String get awayGoals => 'Away Goals';

  @override
  String get top5GD => 'Top 5 GD';

  @override
  String get cardRanking => 'Card Ranking';

  @override
  String get mostYellows => 'Yellows';

  @override
  String get mostReds => 'Reds';

  @override
  String get noData => 'No data';

  @override
  String get recordNotFound => 'Record not found';

  @override
  String get diary => 'Diary';

  @override
  String get details => 'Details';

  @override
  String get broadcast => 'Live';

  @override
  String get lineup => 'Lineup';

  @override
  String get h2h => 'H2H';

  @override
  String get matchDiary => 'Match Diary';

  @override
  String get matchInfo => 'Match Info';

  @override
  String get date => 'Date';

  @override
  String get league => 'League';

  @override
  String get seat => 'Seat';

  @override
  String get additionalInfo => 'More Info';

  @override
  String get weather => 'Weather';

  @override
  String get companions => 'With';

  @override
  String get ticketPrice => 'Ticket';

  @override
  String currencyWon(String price) {
    return '₩$price';
  }

  @override
  String get stadiumFood => 'Food';

  @override
  String get memo => 'Memo';

  @override
  String get mvpToday => 'MVP';

  @override
  String get noStatsInfo => 'No statistics available';

  @override
  String get statsAfterMatch => 'Updated after match';

  @override
  String get possession => 'Poss';

  @override
  String get shots => 'Shots';

  @override
  String get shotsOnTarget => 'On Target';

  @override
  String get corners => 'Corners';

  @override
  String get fouls => 'Fouls';

  @override
  String get offsides => 'Offside';

  @override
  String get yellowCards => 'Yellows';

  @override
  String get redCards => 'Reds';

  @override
  String get matchName => 'Match';

  @override
  String get homeTeam => 'Home Team';

  @override
  String get awayTeam => 'Away Team';

  @override
  String get homeShort => 'Home Record';

  @override
  String get awayShort => 'Away Record';

  @override
  String get score => 'Score';

  @override
  String get photos => 'Photos';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get tags => 'Tags';

  @override
  String get tagVictory => 'Victory';

  @override
  String get tagComeback => 'Comeback';

  @override
  String get tagGoalFest => 'Goal Fest';

  @override
  String get tagCleanSheet => 'Clean Sheet';

  @override
  String get tagFirstMatch => '1st Match';

  @override
  String get tagAway => 'Away';

  @override
  String get currencyUnit => '';

  @override
  String get switchToSearch => 'Search';

  @override
  String get switchToManual => 'Manual';

  @override
  String get addTag => 'Add tag';

  @override
  String get suggestedTags => 'Suggested';

  @override
  String get companionHint => 'e.g. Friends, Family';

  @override
  String get foodReviewHint => 'Food, Taste review';

  @override
  String get priceHint => 'e.g. 50,000';

  @override
  String get penaltyGoal => 'Penalty';

  @override
  String get ownGoal => 'OG';

  @override
  String get goal => 'Goal';

  @override
  String get yellowCard => 'Yellow';

  @override
  String get redCard => 'Red';

  @override
  String get card => 'Card';

  @override
  String get substitution => 'Sub';

  @override
  String get grass => 'Grass';

  @override
  String get resultWin => 'W';

  @override
  String get resultDraw => 'D';

  @override
  String get resultLoss => 'L';

  @override
  String goalsScored(int home, int away) {
    return 'Goals $home : $away';
  }

  @override
  String nMatches(int count) {
    return '$count matches';
  }

  @override
  String get capacity => 'Capacity';

  @override
  String get profileTab => 'Profile';

  @override
  String get careerTab => 'Career';

  @override
  String get matchesTab => 'Matches';

  @override
  String get noMatchRecords => 'No match records';

  @override
  String get assist => 'Assist';

  @override
  String get matchesPlayed => 'Apps';

  @override
  String get playingTime => 'Minutes';

  @override
  String get clubTeams => 'Clubs';

  @override
  String get nationalTeam => 'National Team';

  @override
  String get season => 'Season';

  @override
  String get teamShort => 'Team';

  @override
  String get matches => 'Games';

  @override
  String get rating => 'Rating';

  @override
  String get started => 'Started';

  @override
  String get goalkeeper => 'Goalkeeper';

  @override
  String get defender => 'Defender';

  @override
  String get midfielder => 'Midfielder';

  @override
  String get attacker => 'Forward';

  @override
  String get nationality => 'Nation';

  @override
  String get birthDate => 'Date of Birth';

  @override
  String get age => 'Age';

  @override
  String ageYears(int years) {
    return '$years yrs';
  }

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get birthPlace => 'Birth Place';

  @override
  String get injured => 'Injured';

  @override
  String get suspended => 'Suspended';

  @override
  String get other => 'Other';

  @override
  String get seasonStats => 'Stats';

  @override
  String get playerInfo => 'Player Info';

  @override
  String get playerNotFoundDesc => 'Player info not found';

  @override
  String get error => 'Error';

  @override
  String get currentSeason => 'Current Season';

  @override
  String seasonStatsSummary(String season) {
    return '$season Summary';
  }

  @override
  String get noSeasonStats => 'No season stats';

  @override
  String get loadingSeasonStats => 'Loading season stats...';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get injuryHistory => 'Injury History';

  @override
  String nRecords(int count) {
    return '$count';
  }

  @override
  String get currentlyOut => 'Currently Out';

  @override
  String get recentHistory => 'Recent';

  @override
  String get transferHistory => 'Transfers';

  @override
  String moreTransfers(int count) {
    return '+$count more transfers';
  }

  @override
  String get trophies => 'Trophies';

  @override
  String nTrophies(int count) {
    return '$count';
  }

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get noTimelineInfo => 'No timeline available';

  @override
  String get updatedAfterMatch => 'Updated after match';

  @override
  String assistBy(String name) {
    return 'Assist: $name';
  }

  @override
  String get noLineupInfo => 'No lineup info';

  @override
  String startersCount(int count) {
    return 'Starters ($count)';
  }

  @override
  String get noStarterInfo => 'No starter info';

  @override
  String substitutesCount(int count) {
    return 'Subs ($count)';
  }

  @override
  String get noTeamInfo => 'No team info';

  @override
  String get noH2HRecord => 'No H2H record';

  @override
  String get recentMatches => 'Recent';

  @override
  String get weatherSunny => 'Sunny ☀️';

  @override
  String get weatherCloudy => 'Cloudy ☁️';

  @override
  String get weatherRainy => 'Rainy 🌧️';

  @override
  String get weatherSnowy => 'Snowy ❄️';

  @override
  String get weatherWindy => 'Windy 💨';

  @override
  String get matchRecord => 'Match Record';

  @override
  String get diaryWrite => 'Diary';

  @override
  String get searchResults => 'Results';

  @override
  String get seatInfo => 'Seat';

  @override
  String get seatHint => 'e.g. Block A Row 12 Seat 34';

  @override
  String get goToDiary => 'Write diary →';

  @override
  String get oneLiner => 'One Liner';

  @override
  String get oneLinerHint => 'Describe the match in one line';

  @override
  String get diarySection => 'Match Diary';

  @override
  String get diaryHint => 'How was today\'s match?';

  @override
  String get matchSearch => 'Match Search';

  @override
  String get manualInput => 'Manual';

  @override
  String get teamSearchHint => 'Search by team name (optional)';

  @override
  String get selectLeague => 'Select League';

  @override
  String get enterMatchName => 'Enter match name';

  @override
  String get mySupportedTeam => 'My Team';

  @override
  String get winDrawLossStats => 'Reflects in W/D/L stats';

  @override
  String get searchOrEnterStadium => 'Search or enter stadium';

  @override
  String get todaysMatchRating => 'Match Rating';

  @override
  String get ratingWorst => 'Worst 😢';

  @override
  String get ratingBest => 'Best 🔥';

  @override
  String get todaysMood => 'Today\'s Mood';

  @override
  String get todaysMvp => 'Today\'s MVP';

  @override
  String get selectPlayer => 'Select Player';

  @override
  String get selectMatchFirst => 'Select a match first';

  @override
  String get loginRequired => 'Login required';

  @override
  String get diarySaved => 'Diary saved!';

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get searchPlayerName => 'Search player name';

  @override
  String get noPlayerInfo => 'No player information';

  @override
  String get enterTeamNameDirectly => 'Enter team name';

  @override
  String get teamName => 'Team name';

  @override
  String searchTeamLabel(String label) {
    return 'Search $label';
  }

  @override
  String get moodExcited => 'Excited';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodSatisfied => 'Satisfied';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodDisappointed => 'Disappointed';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodAngry => 'Angry';

  @override
  String get selectThisTeam => 'Select This Team';

  @override
  String get searchByTeamName => 'Search by team name';

  @override
  String get selectLeagueOrSearchTeam =>
      'Select a league or\nsearch for a team';

  @override
  String get venueSearch => 'Venue Search';

  @override
  String get enterVenueNameDirectly => 'Enter venue name directly';

  @override
  String get venueName => 'Venue name';

  @override
  String get selectThisVenue => 'Select This Venue';

  @override
  String get selectCountry => 'Select Country';

  @override
  String get searchByVenueName => 'Search by venue name';

  @override
  String get selectCountryOrSearchVenue =>
      'Select a country or\nsearch for a venue';

  @override
  String get noName => 'No Name';

  @override
  String get editMatchRecord => 'Edit Record';

  @override
  String get editMatchDiary => 'Edit Diary';

  @override
  String get cannotLoadRecord => 'Unable to load record';

  @override
  String get saved => 'Saved!';

  @override
  String get editDiary => 'Edit Diary';

  @override
  String get editDiaryButton => 'Edit Diary →';

  @override
  String get addTagHint => 'Add tag';

  @override
  String get suggestedTagsLabel => 'Suggested';

  @override
  String get additionalInfoSection => 'Additional Info';

  @override
  String get matchInfoNotFound => 'Match not found';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get tabComparison => 'Compare';

  @override
  String get tabStats => 'Stats';

  @override
  String get tabLineup => 'Lineup';

  @override
  String get tabRanking => 'Rank';

  @override
  String get tabPrediction => 'Predict';

  @override
  String get tabComments => 'Comments';

  @override
  String get matchEnded => 'Finished';

  @override
  String get leagueLabel => 'League';

  @override
  String get seasonLabel => 'Season';

  @override
  String get roundLabel => 'Round';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get venueLabel => 'Venue';

  @override
  String get statusLabel => 'Status';

  @override
  String get refereeLabel => 'Referee';

  @override
  String get statusFinished => 'Finished';

  @override
  String get statusHalftime => 'Half Time';

  @override
  String get statusLive => 'Live';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusTBD => 'TBD';

  @override
  String get statusPostponed => 'Postponed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusAET => 'After ET';

  @override
  String get statusPEN => 'After PEN';

  @override
  String get noPredictionInfo => 'No prediction';

  @override
  String get cannotLoadPrediction => 'Cannot load prediction';

  @override
  String get odds => 'Odds';

  @override
  String get drawLabel => 'Draw';

  @override
  String get liveOdds => 'Live Odds';

  @override
  String get allCategory => 'All';

  @override
  String get noBettingInfo => 'No betting info';

  @override
  String get categoryMainBets => 'Main Bets';

  @override
  String get categoryGoalRelated => 'Goals';

  @override
  String get categoryHandicap => 'Handicap';

  @override
  String get categoryHalfTime => 'Half Time';

  @override
  String get categoryTeamRelated => 'Team';

  @override
  String get categoryOther => 'Other';

  @override
  String initialOdd(String value) {
    return 'Initial $value';
  }

  @override
  String get matchPrediction => 'Prediction';

  @override
  String get expectedWinner => 'Expected Winner';

  @override
  String get drawPrediction => 'Draw';

  @override
  String get detailedAnalysis => 'Analysis';

  @override
  String get comparisonForm => 'Form';

  @override
  String get comparisonAttack => 'Attack';

  @override
  String get comparisonDefense => 'Defense';

  @override
  String get comparisonH2H => 'H2H';

  @override
  String get comparisonGoals => 'Goals';

  @override
  String lineupLoadError(String error) {
    return 'Lineup error: $error';
  }

  @override
  String get lineupUpdateBeforeMatch => 'Updated before match';

  @override
  String get substitutes => 'Substitutes';

  @override
  String get substitutionRecord => 'Substitutions';

  @override
  String get bench => 'Bench';

  @override
  String get playerAppsLabel => 'Minutes';

  @override
  String get playerGoalsLabel => 'Goals';

  @override
  String get playerAssistsLabel => 'Assists';

  @override
  String get playerPassAccuracy => 'Pass Accuracy';

  @override
  String get noMatchStats => 'No match stats';

  @override
  String get statsUpdateDuringMatch => 'Updated during/after match';

  @override
  String get attackSection => 'Attack';

  @override
  String get shotsLabel => 'Shots';

  @override
  String get shotsOnLabel => 'Shots on Target';

  @override
  String get offsidesLabel => 'Offsides';

  @override
  String get passSection => 'Passes';

  @override
  String get totalPassLabel => 'Total Passes';

  @override
  String get keyPassLabel => 'Key Passes';

  @override
  String get defenseSection => 'Defense';

  @override
  String get tackleLabel => 'Tackles';

  @override
  String get interceptLabel => 'Interceptions';

  @override
  String get blockLabel => 'Blocks';

  @override
  String get duelDribbleSection => 'Duels & Dribbles';

  @override
  String get duelLabel => 'Duels';

  @override
  String get dribbleLabel => 'Dribbles';

  @override
  String get foulCardSection => 'Fouls & Cards';

  @override
  String get foulLabel => 'Fouls';

  @override
  String get foulDrawnLabel => 'Fouls Drawn';

  @override
  String get cardsLabel => 'Cards';

  @override
  String get goalkeeperSection => 'Goalkeeper';

  @override
  String get savesLabel => 'Saves';

  @override
  String get concededLabel => 'Conceded';

  @override
  String get viewPlayerDetail => 'View Player Detail';

  @override
  String get positionGoalkeeper => 'Goalkeeper';

  @override
  String get positionDefender => 'Defender';

  @override
  String get positionMidfielder => 'Midfielder';

  @override
  String get positionAttacker => 'Attacker';

  @override
  String get missingPlayers => 'Missing Players';

  @override
  String get checkingMissingInfo => 'Checking injury info...';

  @override
  String get injurySuspension => 'Suspended';

  @override
  String get injuryKnee => 'Knee injury';

  @override
  String get injuryHamstring => 'Hamstring injury';

  @override
  String get injuryAnkle => 'Ankle injury';

  @override
  String get injuryMuscle => 'Muscle injury';

  @override
  String get injuryBack => 'Back injury';

  @override
  String get injuryIllness => 'Illness';

  @override
  String get injuryGeneral => 'Injury';

  @override
  String get injuryDoubtful => 'Doubtful';

  @override
  String get injuryOut => 'Out';

  @override
  String get sectionStats => 'Stats';

  @override
  String get sectionBroadcast => 'Timeline';

  @override
  String get cannotLoadTimeline => 'Cannot load timeline';

  @override
  String get possessionLabel => 'Possession';

  @override
  String get cornersLabel => 'Corners';

  @override
  String get foulsLabel => 'Fouls';

  @override
  String get warningsLabel => 'Yellow Cards';

  @override
  String get sendOffsLabel => 'Red Cards';

  @override
  String assistLabel(String name) {
    return 'Assist: $name';
  }

  @override
  String get goalLabel => 'Goal';

  @override
  String get warningCard => 'Yellow';

  @override
  String get sendOffCard => 'Red';

  @override
  String get cardLabel => 'Card';

  @override
  String get substitutionLabel => 'Sub';

  @override
  String get matchNotificationSettings => 'Match Notifications';

  @override
  String get turnOffNotification => 'Turn Off';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get saveLabel => 'Save';

  @override
  String get leagueRanking => 'League Ranking';

  @override
  String get homeAwayRecord => 'Home/Away Record';

  @override
  String get last5Matches => 'Last 5 matches';

  @override
  String get goalStats => 'Goal Stats';

  @override
  String get teamStyleComparison => 'Team Style';

  @override
  String get keyPlayers => 'Key Players';

  @override
  String get h2hRecord => 'Head to Head';

  @override
  String get winLabel => 'W';

  @override
  String get drawShortLabel => 'D';

  @override
  String goalsDisplay(int home, int away) {
    return 'Goals $home : $away';
  }

  @override
  String recentNMatches(int count) {
    return 'Last $count matches';
  }

  @override
  String get noRankingInfo => 'No ranking';

  @override
  String get rankingLabel => 'Rank';

  @override
  String get pointsLabel => 'Points';

  @override
  String get matchesPlayedLabel => 'Played';

  @override
  String get winDrawLossLabel => 'W-D-L';

  @override
  String get goalsForLabel => 'GF';

  @override
  String get goalsAgainstLabel => 'GA';

  @override
  String get goalDiffLabel => 'GD';

  @override
  String get dataLoadFailed => 'Load failed';

  @override
  String get noRecordInfo => 'No record';

  @override
  String get avgGoalsFor => 'Avg Goals';

  @override
  String get avgGoalsAgainst => 'Avg Conceded';

  @override
  String get noStatsAvailable => 'No stats';

  @override
  String get totalGoalsFor => 'Total GF';

  @override
  String get totalGoalsAgainst => 'Total GA';

  @override
  String get goalsPerMatch => 'Goals/Match';

  @override
  String get concededPerMatch => 'Conceded/Match';

  @override
  String get noPlayerStats => 'No player stats';

  @override
  String get goalLeaders => 'Top Scorers';

  @override
  String get assistLeaders => 'Top Assists';

  @override
  String get assistDataLoadFailed => 'Assist load failed';

  @override
  String get cannotLoadPlayerStats => 'Cannot load stats';

  @override
  String get radarWinRate => 'Win Rate';

  @override
  String get radarAttack => 'Attack';

  @override
  String get radarDefense => 'Defense';

  @override
  String get radarCleanSheet => 'Clean Sheet';

  @override
  String get radarHomeRecord => 'Home';

  @override
  String get cleanSheetLabel => 'Clean Sheet';

  @override
  String get failedToScoreLabel => 'Failed to Score';

  @override
  String get cannotLoadRanking => 'Cannot load ranking';

  @override
  String get retryButton => 'Retry';

  @override
  String get teamColumnHeader => 'Team';

  @override
  String get matchesColumnHeader => 'P';

  @override
  String get winsColumnHeader => 'W';

  @override
  String get drawsColumnHeader => 'D';

  @override
  String get lossesColumnHeader => 'L';

  @override
  String get goalDiffColumnHeader => 'GD';

  @override
  String get pointsColumnHeader => 'Pts';

  @override
  String get matchTeams => 'Match Teams';

  @override
  String get relegationLabel => 'Relegation';

  @override
  String get promotionLabel => 'Promotion';

  @override
  String get playoffLabel => 'Playoff';

  @override
  String get advanceLabel => 'Advance';

  @override
  String get matchGroup => 'Match Group';

  @override
  String commentWriteFailed(String error) {
    return 'Comment failed: $error';
  }

  @override
  String get deleteComment => 'Delete Comment';

  @override
  String get deleteCommentConfirm =>
      'Are you sure you want to delete this comment?';

  @override
  String get deleteButton => 'Delete';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get liveComments => 'Live Comments';

  @override
  String get commentsRefreshed => 'Comments refreshed';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get cannotLoadComments => 'Cannot load comments';

  @override
  String get noCommentsYet => 'No comments yet.\nBe the first to comment!';

  @override
  String get beFirstToComment => 'Be the first to comment!';

  @override
  String get commentInputHint => 'Enter comment...';

  @override
  String get justNow => 'Just now';

  @override
  String get noPlayerStatsInfo => 'No player stats available';

  @override
  String get topScorer => 'Top Scorer';

  @override
  String get topAssister => 'Top Assister';

  @override
  String nAssists(int count) {
    return '$count assists';
  }

  @override
  String seasonWithYear(int year, int nextYear) {
    return '$year-$nextYear Season';
  }

  @override
  String get goalDifference => 'GD';

  @override
  String get standingsErrorMessage => 'Could not load standings';

  @override
  String nTimes(int count) {
    return '${count}x';
  }

  @override
  String nPlayers(int count) {
    return '$count players';
  }

  @override
  String get matchTeam => 'Match Team';

  @override
  String get relegation => 'Relegation';

  @override
  String get promotion => 'Promotion';

  @override
  String get playoff => 'Playoff';

  @override
  String groupStageWithYear(int year) {
    return '$year Group Stage';
  }

  @override
  String get qualified => 'Qualified';

  @override
  String get betCategoryMain => 'Main Bets';

  @override
  String get betCategoryGoal => 'Goals';

  @override
  String get betCategoryHandicap => 'Handicap';

  @override
  String get betCategoryHalf => 'Halves';

  @override
  String get betCategoryTeam => 'Team';

  @override
  String get betCategoryOther => 'Other';

  @override
  String get betMatchWinner => 'Match Winner';

  @override
  String get betHomeAway => 'Home/Away';

  @override
  String get betDoubleChance => 'Double Chance';

  @override
  String get betBothTeamsScore => 'Both Teams Score';

  @override
  String get betExactScore => 'Exact Score';

  @override
  String get betGoalsOverUnder => 'Goals Over/Under';

  @override
  String get betOverUnder => 'Over/Under';

  @override
  String get betAsianHandicap => 'Asian Handicap';

  @override
  String get betHandicap => 'Handicap';

  @override
  String get betFirstHalfWinner => '1st Half Winner';

  @override
  String get betSecondHalfWinner => '2nd Half Winner';

  @override
  String get betHalfTimeFullTime => 'HT/FT';

  @override
  String get betOddEven => 'Odd/Even';

  @override
  String get betTotalHome => 'Total - Home';

  @override
  String get betTotalAway => 'Total - Away';

  @override
  String get betCleanSheetHome => 'Clean Sheet - Home';

  @override
  String get betCleanSheetAway => 'Clean Sheet - Away';

  @override
  String get betWinToNilHome => 'Win to Nil - Home';

  @override
  String get betWinToNilAway => 'Win to Nil - Away';

  @override
  String get betCornersOverUnder => 'Corners Over/Under';

  @override
  String get betCardsOverUnder => 'Cards Over/Under';

  @override
  String get betFirstTeamToScore => 'First Team To Score';

  @override
  String get betLastTeamToScore => 'Last Team To Score';

  @override
  String get betHighestScoringHalf => 'Highest Scoring Half';

  @override
  String get betToScoreInBothHalves => 'To Score In Both Halves';

  @override
  String get betHomeWinBothHalves => 'Home Win Both Halves';

  @override
  String get betAwayWinBothHalves => 'Away Win Both Halves';

  @override
  String get cannotLoadLeagueInfo => 'Could not load league info';

  @override
  String get topScorersRanking => 'Top Scorers';

  @override
  String get topAssistsRanking => 'Top Assists';

  @override
  String get noTopScorersInfo => 'No top scorers info';

  @override
  String get noTopAssistsInfo => 'No top assists info';

  @override
  String get cannotLoadTopScorers => 'Could not load top scorers';

  @override
  String get cannotLoadTopAssists => 'Could not load top assists';

  @override
  String get goalsFor => 'GF';

  @override
  String get goalsAgainst => 'GA';

  @override
  String get uclDirect => 'UCL Direct';

  @override
  String get uclQualification => 'UCL Qual';

  @override
  String get uelDirect => 'UEL Direct';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String dateWithWeekday(Object day, Object month, Object weekday) {
    return '$month/$day ($weekday)';
  }

  @override
  String get matchFinished => 'FT';

  @override
  String get noMatchSchedule => 'No matches scheduled';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get champion => 'Champion';

  @override
  String get finalMatch => 'Final';

  @override
  String get runnerUp => 'Runner-up';

  @override
  String get currentRank => 'Current Rank';

  @override
  String get seasonEnd => 'Season End';

  @override
  String get winShortForm => 'W';

  @override
  String get drawShortForm => 'D';

  @override
  String get lossShortForm => 'L';

  @override
  String xMatches(int count) {
    return '$count matches';
  }

  @override
  String xPoints(int count) {
    return '$count pts';
  }

  @override
  String xGoals(int count) {
    return '$count goals';
  }

  @override
  String todayWithDate(String date) {
    return 'Today $date';
  }

  @override
  String tomorrowWithDate(String date) {
    return 'Tomorrow $date';
  }

  @override
  String yesterdayWithDate(String date) {
    return 'Yesterday $date';
  }

  @override
  String get info => 'Info';

  @override
  String get statistics => 'Stats';

  @override
  String get squad => 'Squad';

  @override
  String get transfers => 'Transfers';

  @override
  String get country => 'Country';

  @override
  String get founded => 'Founded';

  @override
  String get type => 'Type';

  @override
  String get code => 'Code';

  @override
  String get manager => 'Manager';

  @override
  String get cleanSheet => 'Clean Sheet';

  @override
  String get failedToScore => 'Failed to Score';

  @override
  String get penaltyKick => 'Penalty Kick';

  @override
  String get hamstring => 'Hamstring';

  @override
  String get illness => 'Illness';

  @override
  String get doubtful => 'Doubtful';

  @override
  String get absent => 'Absent';

  @override
  String get forward => 'Forward';

  @override
  String get incoming => 'Incoming';

  @override
  String get outgoing => 'Outgoing';

  @override
  String get loan => 'Loan';

  @override
  String get transfer => 'Transfer';

  @override
  String foundedYear(int year) {
    return 'Founded $year';
  }

  @override
  String foundedIn(int year) {
    return 'Founded $year';
  }

  @override
  String seasonFormat(int year1, int year2) {
    return '$year1/$year2 Season';
  }

  @override
  String averageFormat(String value) {
    return 'Avg $value';
  }

  @override
  String homeAwayFormat(int home, int away) {
    return 'Home $home / Away $away';
  }

  @override
  String get homeAwayComparison => 'Home/Away Comparison';

  @override
  String get goalsByMinute => 'Goals by Minute';

  @override
  String get injurySuspended => 'Suspended';

  @override
  String get injuryAbsent => 'Absent';

  @override
  String get positionForward => 'Forward';

  @override
  String get filterAll => 'All';

  @override
  String get transferIncoming => 'In';

  @override
  String get transferOutgoing => 'Out';

  @override
  String get transferTypeLoan => 'Loan';

  @override
  String get transferTypePermanent => 'Transfer';

  @override
  String get transferLoanReturn => 'Loan Return';

  @override
  String get freeTransfer => 'Free';

  @override
  String get freeTransferLabel => 'Free Transfer';

  @override
  String get transferFee => 'Fee';

  @override
  String get noTransferInfo => 'No transfer information';

  @override
  String get teamInfo => 'Team Info';

  @override
  String get homeStadium => 'Home Stadium';

  @override
  String careerTeamCount(int count) {
    return 'Career: $count teams';
  }

  @override
  String get seasonRecord => 'Season Record';

  @override
  String get seasonRecordTitle => 'Season Record';

  @override
  String get longestWinStreak => 'Longest Win Streak';

  @override
  String get homeBiggestWin => 'Home Biggest Win';

  @override
  String get awayBiggestWin => 'Away Biggest Win';

  @override
  String get homeBiggestLoss => 'Home Biggest Loss';

  @override
  String get awayBiggestLoss => 'Away Biggest Loss';

  @override
  String get noSchedule => 'No schedule';

  @override
  String get pastMatches => 'Past Matches';

  @override
  String get injuredPlayers => 'Injured Players';

  @override
  String get unknownTeam => 'Unknown';

  @override
  String transferFromTeam(String teamName) {
    return '← $teamName';
  }

  @override
  String transferToTeam(String teamName) {
    return '→ $teamName';
  }

  @override
  String yearsCount(int count) {
    return '$count years';
  }

  @override
  String winStreak(int count) {
    return '$count Win Streak';
  }

  @override
  String currentLanguage(String language) {
    return 'Current: $language';
  }

  @override
  String get languageChangeNote =>
      'Changing the language will update all text in the app.';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get name => 'Name';

  @override
  String get selectFavoriteTeam => 'Select Favorite Team';

  @override
  String get favoriteTeamDescription =>
      'Select your favorite team to see related match info first';

  @override
  String get noFavoriteTeam => 'No team selected';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get timezoneDescription =>
      'Match times will be displayed in your selected timezone';

  @override
  String get matchNotifications => 'Match Notifications';

  @override
  String get matchNotificationsDesc => 'Get notified before matches';

  @override
  String get liveScoreNotifications => 'Live Score Notifications';

  @override
  String get liveScoreNotificationsDesc => 'Goals, red cards, and key events';

  @override
  String get communityNotifications => 'Community Notifications';

  @override
  String get communityNotificationsDesc => 'Likes, comments, and new alerts';

  @override
  String get marketingNotifications => 'Marketing Notifications';

  @override
  String get marketingNotificationsDesc => 'Events, promotions, and more';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get enterDisplayName => 'Enter display name';

  @override
  String get email => 'Email';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordDesc => 'Change regularly for security';

  @override
  String get deleteAccount => 'Withdraw Account';

  @override
  String get deleteAccountDesc => 'All data will be deleted upon withdrawal';

  @override
  String get profilePhoto => 'Change Profile Photo';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get selectFromGalleryDesc => 'Choose from saved photos';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get takePhotoDesc => 'Take a new photo';

  @override
  String get deletePhoto => 'Delete Photo';

  @override
  String get deletePhotoDesc => 'Remove profile photo';

  @override
  String get photoUploaded => 'Photo uploaded. Tap save to apply.';

  @override
  String photoUploadFailed(String error) {
    return 'Photo upload failed: $error';
  }

  @override
  String get photoWillBeDeleted => 'Photo will be deleted. Tap save to apply.';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String updateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordMinLength => 'Enter at least 8 characters';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordChangePreparing => 'Password change coming soon';

  @override
  String get change => 'Change';

  @override
  String get confirmDeleteAccount => 'Are you sure you want to withdraw?';

  @override
  String get deleteWarningRecords => 'All match records will be deleted';

  @override
  String get deleteWarningFavorites => 'Favorites will be deleted';

  @override
  String get deleteWarningPhoto => 'Profile photo will be deleted';

  @override
  String get deleteWarningIrreversible => 'This action cannot be undone';

  @override
  String get deleteAccountPreparing => 'Account withdrawal coming soon';

  @override
  String get timezoneSettingsTitle => 'Timezone Settings';

  @override
  String get searchTimezone => 'Search timezone...';

  @override
  String get currentSetting => 'Current Setting';

  @override
  String timezoneChanged(String name) {
    return 'Timezone changed to $name';
  }

  @override
  String get timezoneKoreaSeoul => 'Korea (Seoul)';

  @override
  String get timezoneJapanTokyo => 'Japan (Tokyo)';

  @override
  String get timezoneChinaShanghai => 'China (Shanghai)';

  @override
  String get timezoneSingapore => 'Singapore';

  @override
  String get timezoneHongKong => 'Hong Kong';

  @override
  String get timezoneThailandBangkok => 'Thailand (Bangkok)';

  @override
  String get timezoneIndonesiaJakarta => 'Indonesia (Jakarta)';

  @override
  String get timezoneIndiaKolkata => 'India (Kolkata)';

  @override
  String get timezoneUAEDubai => 'UAE (Dubai)';

  @override
  String get timezoneUKLondon => 'UK (London)';

  @override
  String get timezoneFranceParis => 'France (Paris)';

  @override
  String get timezoneGermanyBerlin => 'Germany (Berlin)';

  @override
  String get timezoneItalyRome => 'Italy (Rome)';

  @override
  String get timezoneSpainMadrid => 'Spain (Madrid)';

  @override
  String get timezoneNetherlandsAmsterdam => 'Netherlands (Amsterdam)';

  @override
  String get timezoneRussiaMoscow => 'Russia (Moscow)';

  @override
  String get timezoneUSEastNewYork => 'US East (New York)';

  @override
  String get timezoneUSWestLA => 'US West (LA)';

  @override
  String get timezoneUSCentralChicago => 'US Central (Chicago)';

  @override
  String get timezoneBrazilSaoPaulo => 'Brazil (São Paulo)';

  @override
  String get timezoneAustraliaSydney => 'Australia (Sydney)';

  @override
  String get timezoneNewZealandAuckland => 'New Zealand (Auckland)';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get receivePushNotifications => 'Receive Push Notifications';

  @override
  String get masterSwitch => 'Master switch for all notifications';

  @override
  String get favoriteTeamMatchNotifications =>
      'Favorite Team Match Notifications';

  @override
  String get favoriteTeamMatchNotificationsDesc =>
      'Set notifications for your favorite team matches';

  @override
  String get matchStartNotification => 'Match Start Notification';

  @override
  String get matchStartNotificationDesc =>
      'Get notified before favorite team matches';

  @override
  String get notificationTime => 'Notification Time';

  @override
  String get notificationTimeDesc =>
      'When to notify before favorite team matches';

  @override
  String get minutes15Before => '15 min before';

  @override
  String get minutes30Before => '30 min before';

  @override
  String get hour1Before => '1 hour before';

  @override
  String get hours2Before => '2 hours before';

  @override
  String get newMatchScheduleNotification => 'New Match Schedule';

  @override
  String get newMatchScheduleNotificationDesc =>
      'Get notified when new matches are scheduled';

  @override
  String get favoriteTeamLiveNotifications =>
      'Favorite Team Live Notifications';

  @override
  String get favoriteTeamLiveNotificationsDesc =>
      'Set live notifications during favorite team matches';

  @override
  String get liveScoreUpdates => 'Live Score Updates';

  @override
  String get liveScoreUpdatesDesc =>
      'Real-time goal/event notifications during matches';

  @override
  String get notificationPermissionGuide => 'Notification Permission';

  @override
  String get notificationPermissionDesc =>
      'To receive notifications, please enable notification permissions for FootHub in your device settings.';

  @override
  String errorWithMsg(String error) {
    return 'Error: $error';
  }

  @override
  String get helpAndSupportTitle => 'Help & Support';

  @override
  String get faqTitle => 'Frequently Asked Questions';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get appInfo => 'App Info';

  @override
  String get emailInquiry => 'Email Inquiry';

  @override
  String get bugReport => 'Bug Report';

  @override
  String get bugReportDesc => 'Report bugs or issues';

  @override
  String get featureSuggestion => 'Feature Suggestion';

  @override
  String get featureSuggestionDesc => 'Share your ideas with us';

  @override
  String get appVersionLabel => 'App Version';

  @override
  String get buildNumber => 'Build Number';

  @override
  String get developer => 'Developer';

  @override
  String get patchNotes => 'Patch Notes';

  @override
  String get emailCopied =>
      'Unable to open email app. Address copied to clipboard';

  @override
  String get bugReportHint => 'Please describe the bug or issue in detail...';

  @override
  String get featureSuggestionHint =>
      'Please describe the feature you would like...';

  @override
  String get submit => 'Submit';

  @override
  String get legalInfo => 'Legal Information';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get supportWebsite => 'Support Website';

  @override
  String get faqAddRecord => 'How do I add a match record?';

  @override
  String get faqAddRecordAnswer =>
      'You can add a new match record by tapping the + button on the home screen or diary tab. You can also tap \"Record Attendance\" after selecting a match from the schedule.';

  @override
  String get faqAddFavorite => 'How do I add favorite teams?';

  @override
  String get faqAddFavoriteAnswer =>
      'Tap \"Manage\" in the favorites section of your profile, or tap the heart button on the team detail page.';

  @override
  String get faqSchedule => 'Where can I check match schedules?';

  @override
  String get faqScheduleAnswer =>
      'Check match schedules in calendar format from the \"Matches\" tab at the bottom. You can also filter by league.';

  @override
  String get faqNotification => 'How do I set up notifications?';

  @override
  String get faqNotificationAnswer =>
      'Go to Profile > Notification Settings to configure match start notifications, favorite team notifications, and more.';

  @override
  String get faqSupportedLeagues => 'Which leagues are supported?';

  @override
  String get faqSupportedLeaguesAnswer =>
      'We support EPL (England), La Liga (Spain), Bundesliga (Germany), Serie A (Italy), Ligue 1 (France), K-League, Champions League, and Europa League.';

  @override
  String get userDefault => 'User';

  @override
  String get emptyAttendanceTitle => 'No match records';

  @override
  String get emptyAttendanceSubtitle => 'Record your first match attendance!';

  @override
  String get addRecord => 'Add Record';

  @override
  String get emptyDiaryTitle => 'No diary entries';

  @override
  String get emptyDiarySubtitle => 'Watch a match and record it!';

  @override
  String get viewSchedule => 'View Schedule';

  @override
  String get emptyScheduleTitle => 'No matches today';

  @override
  String get emptyScheduleSubtitle => 'Try selecting a different date';

  @override
  String get emptyFavoritesTitle => 'No favorites';

  @override
  String get emptyFavoritesSubtitle => 'Add your favorite teams and players!';

  @override
  String get findTeam => 'Find Team';

  @override
  String get emptySearchTitle => 'No search results';

  @override
  String emptySearchSubtitle(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get errorTitle => 'An error occurred';

  @override
  String get errorDefaultSubtitle => 'Please try again';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String yearMonthFormat(int year, int month) {
    return '$month $year';
  }

  @override
  String get post => 'Post';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String get deletePost => 'Delete Post';

  @override
  String get deletePostConfirm => 'Are you sure you want to delete this post?';

  @override
  String get postNotFound => 'Post not found';

  @override
  String get comment => 'Comment';

  @override
  String commentCount(int count) {
    return '$count comments';
  }

  @override
  String get enterComment => 'Enter a comment';

  @override
  String loadCommentsFailed(String error) {
    return 'Failed to load comments: $error';
  }

  @override
  String get myAttendanceStats => 'My Attendance Stats';

  @override
  String get totalAttendance => 'Total';

  @override
  String attendanceCount(int count) {
    return '$count matches';
  }

  @override
  String winRatePercent(String rate) {
    return '$rate%';
  }

  @override
  String mostVisited(String stadium, int count) {
    return 'Most visited: $stadium (${count}x)';
  }

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get attendanceStats => 'Attendance Stats';

  @override
  String get frequentStadiums => 'Frequent Stadiums';

  @override
  String get noAttendanceRecordsYet => 'No attendance records yet';

  @override
  String get postsLabel => 'Posts';

  @override
  String get attendanceLabel => 'Matches';

  @override
  String get championship => 'Championship';

  @override
  String get lowerSplit => 'Lower Split';

  @override
  String get promotionPlayoff => 'Promotion PO';

  @override
  String get competition => 'Competition';

  @override
  String get seasonFormatChanged => 'New league format from 2024-25 season';

  @override
  String get standingsNotAvailable => 'Standings not yet available';

  @override
  String get checkScheduleTab => 'Check match schedule in Schedule tab';

  @override
  String get rankHeader => 'Rank';

  @override
  String get playerHeader => 'Player';

  @override
  String get appsHeader => 'Apps';

  @override
  String get goalsHeader => 'Goals';

  @override
  String get assistsHeader => 'Ast';

  @override
  String get teamHeader => 'Team';

  @override
  String get matchesHeader => 'P';

  @override
  String get wonHeader => 'W';

  @override
  String get drawnHeader => 'D';

  @override
  String get lostHeader => 'L';

  @override
  String get gfHeader => 'GF';

  @override
  String get gaHeader => 'GA';

  @override
  String get gdHeader => 'GD';

  @override
  String get ptsHeader => 'Pts';

  @override
  String get recentFormTitle => 'Recent Form';

  @override
  String get homeAwayStrong => 'Home/Away Leaders';

  @override
  String get homeStrong => 'Home Strong';

  @override
  String get awayStrong => 'Away Strong';

  @override
  String get bottomAnalysisTitle => 'Bottom Analysis';

  @override
  String get mostLossesLabel => 'Most Losses';

  @override
  String lossesCount(int count) {
    return '${count}L';
  }

  @override
  String get mostConcededLabel => 'Most Conceded';

  @override
  String concededCount(int count) {
    return '$count GA';
  }

  @override
  String get leagueOverviewTitle => 'League Overview';

  @override
  String get totalGoalsLabel => 'Total Goals';

  @override
  String get goalsPerGameLabel => 'Goals/Game';

  @override
  String get homeWinsLabel => 'Home Wins';

  @override
  String get awayWinsLabel => 'Away Wins';

  @override
  String get homeWinShort => 'Home W';

  @override
  String get awayWinShort => 'Away W';

  @override
  String gamesCount(int count) {
    return '$count games';
  }

  @override
  String get recentMatchRecords => 'Recent Match Records';

  @override
  String totalCount(int count) {
    return '$count total';
  }

  @override
  String get searchTitleContentAuthor => 'Search title, content, author';

  @override
  String get hasMatchRecord => 'Has match record';

  @override
  String get clearAll => 'Clear all';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get writeFirstPost => 'Be the first to write a post!';

  @override
  String get writePost => 'Write';

  @override
  String get noSearchResultsForQuery => 'No search results';

  @override
  String get clearSearchQuery => 'Clear search';

  @override
  String get reset => 'Reset';

  @override
  String get showOnlyWithMatchRecord => 'Show only posts with match records';

  @override
  String get matchDate => 'Match Date';

  @override
  String get selectLeagueFilter => 'Select League';

  @override
  String get allLeagues => 'All';

  @override
  String get searching => 'Searching...';

  @override
  String get searchMatch => 'Search Match';

  @override
  String searchResultsCount(int count) {
    return 'Results ($count)';
  }

  @override
  String get noMatchesOnDate => 'No matches on this date';

  @override
  String moreMatchesCount(int count) {
    return '$count more';
  }

  @override
  String get applySelectedMatch => 'Apply selected match filter';

  @override
  String get apply => 'Apply';

  @override
  String get selected => 'Selected';

  @override
  String get enterTitle => 'Please enter a title';

  @override
  String get enterContent => 'Please enter content';

  @override
  String get postEdited => 'Post updated';

  @override
  String get postCreated => 'Post created';

  @override
  String get selectMatchRecord => 'Select Match Record';

  @override
  String get deselectRecord => 'Deselect';

  @override
  String get loadingStats => 'Loading stats...';

  @override
  String get myAttendanceStatsTitle => 'My Attendance Stats';

  @override
  String totalMatchesCount(int count) {
    return '$count matches';
  }

  @override
  String winRatePercentValue(String rate) {
    return '$rate%';
  }

  @override
  String mostVisitedStadium(String stadium, int count) {
    return 'Most visited: $stadium (${count}x)';
  }

  @override
  String get editPost => 'Edit Post';

  @override
  String get register => 'Submit';

  @override
  String get enterTitleHint => 'Enter title';

  @override
  String get matchRecordLabel => 'Match Record';

  @override
  String get loadMyMatchRecord => 'Load my match record (optional)';

  @override
  String get myAttendanceStatsLabel => 'My Attendance Stats';

  @override
  String get showMyStats => 'Share my stats (optional)';

  @override
  String get contentHint =>
      'Enter content\n\nShare your match experience, tips, and more!';

  @override
  String get tagsOptional => 'Tags (optional)';

  @override
  String get tagInputHint => 'Enter tag (max 5)';

  @override
  String get add => 'Add';

  @override
  String get communityGuideline =>
      'Content that defames or offends others may be removed.';

  @override
  String get postNotFoundError => 'Post not found';

  @override
  String get noEditPermission => 'No edit permission';

  @override
  String get noDeletePermission => 'No delete permission';

  @override
  String get commentNotFoundError => 'Comment not found';

  @override
  String get matchLog => 'FootHub';

  @override
  String get myFootballRecord => 'My Football Attendance Record';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get invalidEmailFormat => 'Please enter a valid email format';

  @override
  String get enterPasswordPlease => 'Please enter your password';

  @override
  String get loginAction => 'Login';

  @override
  String get signUpAction => 'Sign Up';

  @override
  String get noAccountSignUp => 'Don\'t have an account? Sign up';

  @override
  String get hasAccountLogin => 'Already have an account? Login';

  @override
  String get orDivider => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get emailAlreadyInUse => 'This email is already in use';

  @override
  String get invalidEmailError => 'Invalid email format';

  @override
  String get weakPasswordError => 'Password is too weak';

  @override
  String get userNotFoundError => 'No account found with this email';

  @override
  String get wrongPasswordError => 'Incorrect password';

  @override
  String get authServiceUnavailable =>
      'Authentication service unavailable. Please try again later.';

  @override
  String get genericAuthError => 'An error occurred. Please try again.';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get enterRegisteredEmail => 'Enter your registered email';

  @override
  String get sendButton => 'Send';

  @override
  String get passwordResetEmailSent => 'Password reset email sent';

  @override
  String get untilOpening => 'Until Opening';

  @override
  String get scheduleTab => 'Schedule';

  @override
  String get infoTab => 'Info';

  @override
  String get squadTab => 'Squad';

  @override
  String get selectCountryButton => 'Select Country';

  @override
  String get errorPrefix => 'Error';

  @override
  String get cannotLoadTeamInfo => 'Cannot load team info';

  @override
  String get basicInfoSection => 'Basic Info';

  @override
  String get countryLabel => 'Country';

  @override
  String get homeStadiumLabel => 'Home Stadium';

  @override
  String get capacityLabel => 'Capacity';

  @override
  String capacityValue(int count) {
    return '$count';
  }

  @override
  String get foundedLabel => 'Founded';

  @override
  String get last5Form => 'Last 5 Matches Form';

  @override
  String get noFormInfo => 'No form info available';

  @override
  String get loseShort => 'L';

  @override
  String get cannotLoadFormInfo => 'Cannot load form info';

  @override
  String get competitionsSection => 'Competitions';

  @override
  String get tapForLeagueDetail => 'Tap for league details';

  @override
  String get noCompetitionInfo => 'No competition info';

  @override
  String get cannotLoadCompetitionInfo => 'Cannot load competition info';

  @override
  String get noSquadInfo => 'No squad info';

  @override
  String get goalkeepersSection => 'Goalkeepers';

  @override
  String get defendersSection => 'Defenders';

  @override
  String get midfieldersSection => 'Midfielders';

  @override
  String get attackersSection => 'Attackers';

  @override
  String get squadInfoNote =>
      'National team squads are\ncalled up per competition';

  @override
  String get worldCup => 'World Cup';

  @override
  String get worldCupQualAfc => 'World Cup Qualifiers (AFC)';

  @override
  String get asianCup => 'Asian Cup';

  @override
  String get friendlyMatch => 'Friendly Match';

  @override
  String get matchNameHint => 'e.g. Friendly, Preseason, FA Cup';

  @override
  String get leaguesByCountry => 'Leagues by Country';

  @override
  String get mainCountries => 'Main Countries';

  @override
  String get allCountries => 'All Countries';

  @override
  String get noCountryCode => 'No country code';

  @override
  String get leagueSection => 'Leagues';

  @override
  String get cupSection => 'Cups';

  @override
  String get otherSection => 'Other';

  @override
  String get invalidLeagueId => 'Invalid league ID';

  @override
  String get deleteAction => 'Delete';

  @override
  String get justNowShort => 'Just now';

  @override
  String get noBettingInCategory => 'No betting in this category';

  @override
  String get anonymousUser => 'Anonymous';

  @override
  String get cannotFindComment => 'Cannot find comment';

  @override
  String get noDeletePermissionComment => 'No delete permission';

  @override
  String get countryKorea => 'South Korea';

  @override
  String get countryEngland => 'England';

  @override
  String get countrySpain => 'Spain';

  @override
  String get countryGermany => 'Germany';

  @override
  String get countryItaly => 'Italy';

  @override
  String get countryFrance => 'France';

  @override
  String get countryJapan => 'Japan';

  @override
  String noLeaguesInCountry(String country) {
    return 'No leagues registered in $country';
  }

  @override
  String get standingsTab => 'Standings';

  @override
  String get scorersTab => 'Scorers';

  @override
  String get assistsTab => 'Assists';

  @override
  String get statsTab => 'Stats';

  @override
  String get noStandingsData => 'No standings information';

  @override
  String get cannotLoadStandingsForSeason =>
      'Cannot load standings for this season';

  @override
  String get noGoalRankData => 'No goal ranking information';

  @override
  String get noAssistRankData => 'No assist ranking information';

  @override
  String get noLeagueStatsData => 'No league stats information';

  @override
  String get leagueOverviewCard => 'League Overview';

  @override
  String nGamesLabel(int count) {
    return '${count}G';
  }

  @override
  String get teamRankingCard => 'Team Ranking';

  @override
  String get mostScoringTeam => 'Most Goals';

  @override
  String get mostConcededTeam => 'Most Conceded';

  @override
  String get mostWinsTeam => 'Most Wins';

  @override
  String get mostDrawsTeam => 'Most Draws';

  @override
  String nGoalsLabel(int count) {
    return '${count}G';
  }

  @override
  String nWinsLabel(int count) {
    return '${count}W';
  }

  @override
  String nDrawsLabel(int count) {
    return '${count}D';
  }

  @override
  String get goalAnalysisCard => 'Goal Analysis';

  @override
  String totalNGoals(int count) {
    return 'Total ${count}G';
  }

  @override
  String get top5GoalDiff => 'Top 5 Goal Difference';

  @override
  String errorLabel(String error) {
    return 'Error: $error';
  }

  @override
  String get rankColumn => 'Rank';

  @override
  String get teamColumn => 'Team';

  @override
  String get matchesColumn => 'M';

  @override
  String get winColumn => 'W';

  @override
  String get drawColumn => 'D';

  @override
  String get loseColumn => 'L';

  @override
  String get goalsForColumn => 'GF';

  @override
  String get goalsAgainstColumn => 'GA';

  @override
  String get goalDiffColumn => 'GD';

  @override
  String get pointsColumn => 'Pts';

  @override
  String get playerColumn => 'Player';

  @override
  String get appsColumn => 'Apps';

  @override
  String get goalsColumn => 'Goals';

  @override
  String get assistsColumn => 'Ast';

  @override
  String get dateFormatFull => 'MMM d, yyyy (E)';

  @override
  String get dateFormatMedium => 'MMM d, yyyy';

  @override
  String get dateFormatWithTime => 'MMM d, yyyy (E) HH:mm';

  @override
  String get dateFormatShort => 'MM.dd (E)';

  @override
  String get dateFormatHeader => 'EEEE, MMM d';

  @override
  String get dateFormatDiary => 'MMM d, yyyy (E)';

  @override
  String get dateFormatSlash => 'MMM d, yyyy (E)';

  @override
  String searchAllMatchesForDate(String date) {
    return 'Search all matches on $date';
  }

  @override
  String searchLeagueMatchesForDate(String date, String league) {
    return 'Search $league matches on $date';
  }

  @override
  String stadiumListForCountry(String country) {
    return '$country Stadiums';
  }

  @override
  String get leagueEPL => 'EPL';

  @override
  String get leagueLaLiga => 'La Liga';

  @override
  String get leagueSerieA => 'Serie A';

  @override
  String get leagueBundesliga => 'Bundesliga';

  @override
  String get leagueLigue1 => 'Ligue 1';

  @override
  String get leagueKLeague1 => 'K League 1';

  @override
  String get leagueKLeague2 => 'K League 2';

  @override
  String get leagueUCL => 'UCL';

  @override
  String get leagueUEL => 'UEL';

  @override
  String get leagueInternational => 'International';

  @override
  String leagueTeamList(String league) {
    return '$league Teams';
  }

  @override
  String get worldCup2026 => '2026 FIFA World Cup';

  @override
  String get myDiaryTitle => 'My Match Diary';

  @override
  String yearlySummary(int year) {
    return '$year Match Summary';
  }

  @override
  String get matchUnit => 'matches';

  @override
  String nMatchesUnit(int count) {
    return '$count matches';
  }

  @override
  String nYearsUnit(int count) {
    return '$count years';
  }

  @override
  String get totalViews => 'Total';

  @override
  String get averageRating => 'Avg Rating';

  @override
  String get pointsUnit => 'pts';

  @override
  String get invalidCoachId => 'Invalid coach ID';

  @override
  String get homeGoal => 'Home Goal';

  @override
  String get awayGoal => 'Away Goal';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get loadFailedShort => 'Load failed';

  @override
  String get ageLabel => 'Age';

  @override
  String get birthDateLabel => 'Birth Date';

  @override
  String get birthPlaceLabel => 'Birth Place';

  @override
  String get championTitle => 'Champion';

  @override
  String get runnerUpTitle => 'Runner-up';

  @override
  String get careerTitle => 'Career';

  @override
  String get currentLabel => 'Current';

  @override
  String get suspendedLabel => 'Suspended';

  @override
  String get worldCupShort => 'WC';

  @override
  String get asianCupShort => 'Asian Cup';

  @override
  String get friendlyMatchLabel => 'Friendly';

  @override
  String ageYearsValue(int age) {
    return '$age yrs';
  }

  @override
  String get birthCountry => 'Birth Country';

  @override
  String get coachCareer => 'Coaching Career';

  @override
  String careerYears(int years) {
    return '$years yrs';
  }

  @override
  String get trophyRecord => 'Trophy Record';

  @override
  String andNMore(int count) {
    return '+$count more';
  }

  @override
  String get mostWatchedTeam => 'Most Watched Team';

  @override
  String get selectSeason => 'Select Season';

  @override
  String get languageSubtitle => 'Korean, English';

  @override
  String get suspensionHistory => 'Suspension History';

  @override
  String nCases(int count) {
    return '$count cases';
  }

  @override
  String get currentlySuspended => 'Currently Suspended';

  @override
  String get coachInfo => 'Coach Info';

  @override
  String get errorLoginRequired => 'Login required';

  @override
  String get errorPostNotFound => 'Post not found';

  @override
  String get errorPostEditPermissionDenied => 'No permission to edit';

  @override
  String get errorPostDeletePermissionDenied => 'No permission to delete';

  @override
  String get errorCommentNotFound => 'Comment not found';

  @override
  String get errorCommentDeletePermissionDenied => 'No permission to delete';

  @override
  String get errorNetworkError => 'Network error occurred';

  @override
  String get errorUnknown => 'An unknown error occurred';

  @override
  String get injuryGroin => 'Groin injury';

  @override
  String get injuryShoulder => 'Shoulder injury';

  @override
  String get injuryAchilles => 'Achilles injury';

  @override
  String get injuryCalf => 'Calf injury';

  @override
  String get injuryThigh => 'Thigh injury';

  @override
  String get injuryHip => 'Hip injury';

  @override
  String get injuryFracture => 'Fracture';

  @override
  String get injuryConcussion => 'Concussion';

  @override
  String get injuryLigament => 'Ligament injury';

  @override
  String get injurySurgery => 'Surgery';

  @override
  String get statusSuspension => 'Suspension';

  @override
  String get statusRedCard => 'Red card ban';

  @override
  String get statusYellowCard => 'Yellow card accumulation';

  @override
  String get statusBan => 'Ban';

  @override
  String get statusDisciplinary => 'Disciplinary';

  @override
  String get statusMissing => 'Missing';

  @override
  String get statusPersonal => 'Personal reasons';

  @override
  String get statusInternational => 'International duty';

  @override
  String get statusRest => 'Rest';

  @override
  String get statusFitness => 'Fitness';

  @override
  String get statusSuspended => 'Suspended';

  @override
  String get statusInjury => 'Injury';

  @override
  String get statusDoubtful => 'Doubtful';

  @override
  String get statusAbsent => 'Absent';

  @override
  String get betFirstHalfOU => '1st Half O/U';

  @override
  String get betSecondHalfOU => '2nd Half O/U';

  @override
  String get betHalfFullTime => 'Half/Full Time';

  @override
  String get betHomeTeamGoals => 'Home Team Goals';

  @override
  String get betAwayTeamGoals => 'Away Team Goals';

  @override
  String get betDrawNoBet => 'Draw No Bet';

  @override
  String get betResultBothScore => 'Result + Both Score';

  @override
  String get betFirstHalfExact => '1st Half Exact Score';

  @override
  String get betGoalsDifference => 'Goals Difference';

  @override
  String get periodOngoing => 'Ongoing';

  @override
  String get periodCurrent => 'Current';

  @override
  String get errorNetwork => 'Please check your internet connection';

  @override
  String get errorTimeout => 'Server is not responding. Please try again later';

  @override
  String get errorServer =>
      'A temporary error occurred. Please try again later';

  @override
  String get errorFirebasePermission =>
      'You don\'t have permission to access this';

  @override
  String get errorFirebaseNotFound => 'The requested data was not found';

  @override
  String get errorFirebaseUnavailable => 'Service is temporarily unavailable';

  @override
  String get accountDeleted => 'Account withdrawal completed';

  @override
  String accountDeleteFailed(String error) {
    return 'Account withdrawal failed: $error';
  }

  @override
  String get report => 'Report';

  @override
  String get reportPost => 'Report Post';

  @override
  String get reportComment => 'Report Comment';

  @override
  String get reportUser => 'Report User';

  @override
  String get reportReason => 'Reason for Report';

  @override
  String get reportReasonSpam => 'Spam/Advertising';

  @override
  String get reportReasonHarassment => 'Harassment/Abuse';

  @override
  String get reportReasonInappropriate => 'Inappropriate Content';

  @override
  String get reportReasonFalseInfo => 'False Information';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportAdditionalInfo => 'Additional Details (Optional)';

  @override
  String get reportAdditionalInfoHint =>
      'Please provide more details about the report';

  @override
  String get reportSubmit => 'Submit Report';

  @override
  String get reportSubmitted => 'Report has been submitted';

  @override
  String reportFailed(String error) {
    return 'Report failed: $error';
  }

  @override
  String get reportAlreadySubmitted => 'You have already reported this content';

  @override
  String get reportConfirmTitle => 'Submit Report?';

  @override
  String get reportConfirmMessage => 'False reports may result in penalties.';

  @override
  String get blockUser => 'Block User';

  @override
  String get blockUserConfirm => 'Block this user?';

  @override
  String get blockUserDesc => 'Manage blocked users';

  @override
  String get userBlocked => 'User has been blocked';

  @override
  String get blockedUsersManagement => 'Blocked Users';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get blockedUser => 'Blocked User';

  @override
  String get unblock => 'Unblock';

  @override
  String get unblockUser => 'Unblock User';

  @override
  String get unblockUserConfirm => 'Unblock this user?';

  @override
  String get userUnblocked => 'User has been unblocked';
}
