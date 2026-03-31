const String baseUrl = "https://gubajdullindanis0.fvds.ru";
const String apiV1 = "$baseUrl/api/v1";
const String apiAuth = "$apiV1/auth";
const String registerUrl = "$apiAuth/register";
const String authUrl = "$apiAuth/login";
const String meUrl = "$apiAuth/me";
const String logoutUrl = "$apiAuth/logout";
const String refreshUrl = "$apiAuth/refresh";

const String usersUrl = "$apiV1/users";
const String searchUsersUrl = "$apiV1/users/search";
const String getConversationsUrl = "$apiV1/get_conversations";
String getOrCreateDialogUrl(String userName) => "$apiV1/get_or_create_dialog/${Uri.encodeComponent(userName)}";
String getOrCreateSavedUrl = "$apiV1/get_or_create_saved";

const String createConversationUrl = "$apiV1/create_group_conversation";
// String addUserToConversationUrl(int conversationId, String userName)
//   => "$apiV1/conversations/$conversationId/add/${Uri.encodeComponent(userName)}";
// String removeUserFromConversationUrl(int conversationId, String userName)
//   => "$apiV1/conversations/$conversationId/users/${Uri.encodeComponent(userName)}";"


const String followUrl = "$apiV1/follow";
String getFollowersUrl(int limit, int offset) => "$apiV1/get_followers/$limit/$offset";
String getFollowingUrl(int limit, int offset) => "$apiV1/get_following/$limit/$offset";

const String webSocketUrl = "wss://gubajdullindanis0.fvds.ru/api/v1/ws2/";
