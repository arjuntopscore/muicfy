import 'package:spotify/spotify.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class SpotifyService {
  // Use the Client ID and Secret you generated from the Spotify Developer Dashboard
  static const String clientId = '0bd85ff775674f13828a1e5c674390da';
  static const String clientSecret = 'ae7d342b1fcc42549dfeb5827999adf0';
  
  // This must exactly match the Redirect URI you put in the Spotify dashboard!
  static const String redirectUrl = 'musicapp://callback';

  SpotifyApi? _spotify;

  /// Logs the user into Spotify and gets the access token.
  Future<bool> authenticate() async {
    try {
      final grant = SpotifyApi.authorizationCodeGrant(
        SpotifyApiCredentials(clientId, clientSecret),
      );

      final authUrl = grant.getAuthorizationUrl(
        Uri.parse(redirectUrl),
        scopes: [
          'user-library-read',
          'playlist-read-private',
          'playlist-read-collaborative'
        ],
      );

      // This will open a browser window for the user to log in to Spotify
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'musicapp',
      );

      if (result.isNotEmpty) {
        // Exchange the code for an access token using the full callback URL
        _spotify = await SpotifyApi.fromAuthCodeGrant(
          grant,
          result,
        );
        print("Successfully connected to Spotify!");
        return true;
      }
    } catch (e) {
      print('Error authenticating with Spotify: $e');
    }
    return false;
  }

  /// Returns whether the user is currently logged in.
  bool get isLoggedIn => _spotify != null;

  /// Fetches all playlists for the logged-in user.
  Future<List<PlaylistSimple>> getUserPlaylists() async {
    if (_spotify == null) return [];
    
    try {
      final playlistsIterable = await _spotify!.playlists.me.all();
      // We must call .toList() here to force the network request to complete
      // inside the try-catch block, otherwise it throws unhandled later!
      return playlistsIterable.toList();
    } catch (e) {
      print('Error getting playlists: $e');
      return [];
    }
  }

  /// Fetches all tracks from a specific playlist.
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    if (_spotify == null) return [];
    
    try {
      final tracksList = await _spotify!.playlists.getTracksByPlaylistId(playlistId).all();
      return tracksList.toList();
    } catch (e) {
      print('Error getting playlist tracks: $e');
      return [];
    }
  }
}
