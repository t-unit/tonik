import 'package:dio/dio.dart';
import 'package:music_streaming_api/music_streaming_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  const port = 8090;
  const baseUrl = 'http://localhost:$port/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  AlbumsApi buildAlbumsApi({required String responseStatus}) {
    return AlbumsApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  group('getAnAlbum', () {
    test('200', () async {
      final albumsApi = buildAlbumsApi(responseStatus: '200');

      final response = await albumsApi.getAnAlbum(id: '123');

      expect(response, isA<TonikSuccess<GetAnAlbumResponse>>());
      final success = response as TonikSuccess<GetAnAlbumResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetAnAlbumResponse200>());

      final value = success.value as GetAnAlbumResponse200;
      expect(value.body, isA<AlbumObject>());
      final albumBase = value.body.albumBase;

      expect(albumBase, isA<AlbumBase>());
      expect(albumBase.albumType, isA<AlbumBaseAlbumTypeModel>());
      expect(AlbumBaseAlbumTypeModel.values.map((v) => v.rawValue), [
        'album',
        'single',
        'compilation',
      ]);
      expect(albumBase.totalTracks, isA<int>());
      expect(albumBase.availableMarkets, isA<List<String>>());
      expect(albumBase.externalUrls, isA<AlbumBaseExternalUrlsAllOfModel>());

      expect(albumBase.href, isA<String>());
      expect(albumBase.id, isA<String>());
      expect(albumBase.images, isA<List<ImageObject>>());
      expect(albumBase.name, isA<String>());
      expect(albumBase.releaseDate, isA<String>());
      expect(
        albumBase.releaseDatePrecision,
        isA<AlbumBaseReleaseDatePrecisionModel>(),
      );
      expect(AlbumBaseReleaseDatePrecisionModel.values.map((v) => v.rawValue), [
        'year',
        'month',
        'day',
      ]);
      expect(albumBase.restrictions, isA<AlbumBaseRestrictionsAllOfModel?>());
      expect(albumBase.$type, isA<AlbumBaseTypeModel>());
      expect(AlbumBaseTypeModel.values.map((v) => v.rawValue), ['album']);
      expect(albumBase.uri, isA<String>());

      final externalUrls = albumBase.externalUrls.externalUrlObject;
      expect(externalUrls.spotify, isA<String>());

      final image = albumBase.images.first;
      expect(image.url, isA<String>());
      expect(image.height, isA<int?>());
      expect(image.width, isA<int?>());

      final releaseDatePrecision =
          albumBase.restrictions?.albumRestrictionObject;
      expect(
        releaseDatePrecision?.reason,
        isA<AlbumRestrictionObjectReasonModel>(),
      );
      expect(AlbumRestrictionObjectReasonModel.values.map((v) => v.rawValue), [
        'market',
        'product',
        'explicit',
      ]);

      final albumObject = value.body.albumObjectModel;
      expect(albumObject, isA<AlbumObjectModel>());

      // Note: api document intends to have properties of
      // [SimplifiedArtistObject] to be non-nullable, but
      // required is defined on wrong level and will get
      // ignored by tonic.
      expect(albumObject.artists, isA<List<SimplifiedArtistObject>?>());
      final artist = albumObject.artists?.first;
      expect(
        artist?.externalUrls,
        isA<SimplifiedArtistObjectExternalUrlsAllOfModel?>(),
      );
      expect(artist?.externalUrls?.externalUrlObject, isA<ExternalUrlObject>());
      expect(artist?.externalUrls?.externalUrlObject.spotify, isA<String?>());
      expect(artist?.href, isA<String?>());
      expect(artist?.id, isA<String?>());
      expect(artist?.name, isA<String?>());
      expect(artist?.$type, isA<SimplifiedArtistObjectTypeModel?>());
      expect(SimplifiedArtistObjectTypeModel.values.map((v) => v.rawValue), [
        'artist',
      ]);
      expect(artist?.uri, isA<String?>());

      expect(albumObject.tracks, isA<AlbumObjectTracksAllOfModel?>());
      expect(
        albumObject.tracks?.pagingSimplifiedTrackObject,
        isA<PagingSimplifiedTrackObject?>(),
      );
      final track = albumObject.tracks?.pagingSimplifiedTrackObject;
      expect(track?.pagingObject, isA<PagingObject>());
      expect(track?.pagingObject.href, isA<String>());
      expect(track?.pagingObject.limit, isA<int>());
      expect(track?.pagingObject.next, isA<String?>());
      expect(track?.pagingObject.offset, isA<int>());
      expect(track?.pagingObject.previous, isA<String?>());
      expect(track?.pagingObject.total, isA<int>());

      expect(
        track?.pagingObject,
        isA<PagingObject>(),
      );
      expect(
        track?.pagingSimplifiedTrackObjectModel.items,
        isA<List<SimplifiedTrackObject>>(),
      );
      final trackItem = track?.pagingSimplifiedTrackObjectModel.items?.first;
      expect(trackItem?.artists, isA<List<SimplifiedArtistObject>?>());
      expect(trackItem?.availableMarkets, isA<List<String>?>());
      expect(trackItem?.discNumber, isA<int?>());
      expect(trackItem?.durationMs, isA<int?>());
      expect(trackItem?.explicit, isA<bool?>());
      expect(
        trackItem?.externalUrls,
        isA<SimplifiedTrackObjectExternalUrlsAllOfModel?>(),
      );
      expect(
        trackItem?.externalUrls?.externalUrlObject,
        isA<ExternalUrlObject>(),
      );
      expect(
        trackItem?.externalUrls?.externalUrlObject.spotify,
        isA<String?>(),
      );
      expect(trackItem?.href, isA<String?>());
      expect(trackItem?.id, isA<String?>());
      expect(trackItem?.isPlayable, isA<bool?>());
      expect(
        trackItem?.linkedFrom,
        isA<SimplifiedTrackObjectLinkedFromAllOfModel?>(),
      );
      expect(
        trackItem?.linkedFrom?.linkedTrackObject.externalUrls,
        isA<LinkedTrackObjectExternalUrlsAllOfModel?>(),
      );
      expect(trackItem?.linkedFrom?.linkedTrackObject.href, isA<String?>());
      expect(trackItem?.linkedFrom?.linkedTrackObject.id, isA<String?>());
      expect(trackItem?.linkedFrom?.linkedTrackObject.$type, isA<String?>());
      expect(trackItem?.linkedFrom?.linkedTrackObject.uri, isA<String?>());
      expect(
        trackItem?.restrictions,
        isA<SimplifiedTrackObjectRestrictionsAllOfModel?>(),
      );
      expect(
        trackItem?.restrictions?.trackRestrictionObject.reason,
        isA<String>(),
      );
      expect(trackItem?.name, isA<String?>());
      expect(trackItem?.previewUrl, isA<String?>());
      expect(trackItem?.trackNumber, isA<int?>());
      expect(trackItem?.$type, isA<String?>());
      expect(trackItem?.uri, isA<String?>());
      expect(trackItem?.isLocal, isA<bool?>());

      expect(albumObject.copyrights, isA<List<CopyrightObject>?>());
      final copyright = albumObject.copyrights?.first;
      expect(copyright?.text, isA<String?>());
      expect(copyright?.$type, isA<String?>());

      expect(albumObject.externalIds, isA<AlbumObjectExternalIdsAllOfModel?>());
      expect(albumObject.genres, isA<List<String>?>());
      expect(albumObject.label, isA<String?>());
      expect(albumObject.popularity, isA<int?>());
    });

    test('401', () async {
      final albumsApi = buildAlbumsApi(responseStatus: '401');

      final response = await albumsApi.getAnAlbum(id: 'abc', market: 'en');

      expect(response, isA<TonikSuccess<GetAnAlbumResponse>>());
      final success = response as TonikSuccess<GetAnAlbumResponse>;
      expect(success.response.statusCode, 401);
      expect(success.value, isA<GetAnAlbumResponse401>());

      final value = success.value as GetAnAlbumResponse401;
      expect(value.body, isA<UnauthorizedBodyModel>());
      expect(value.body.error, isA<ErrorObject>());
      expect(value.body.error.status, isA<int>());
      expect(value.body.error.message, isA<String>());
    });

    test('403', () async {
      final albumsApi = buildAlbumsApi(responseStatus: '403');

      final response = await albumsApi.getAnAlbum(id: 'abc', market: 'en');

      expect(response, isA<TonikSuccess<GetAnAlbumResponse>>());
      final success = response as TonikSuccess<GetAnAlbumResponse>;
      expect(success.response.statusCode, 403);
      expect(success.value, isA<GetAnAlbumResponse403>());

      final value = success.value as GetAnAlbumResponse403;
      expect(value.body, isA<ForbiddenBodyModel>());
      expect(value.body.error, isA<ErrorObject>());
      expect(value.body.error.status, isA<int>());
      expect(value.body.error.message, isA<String>());
    });

    test('429', () async {
      final albumsApi = buildAlbumsApi(responseStatus: '429');

      final response = await albumsApi.getAnAlbum(id: 'abc', market: 'en');

      expect(response, isA<TonikSuccess<GetAnAlbumResponse>>());
      final success = response as TonikSuccess<GetAnAlbumResponse>;
      expect(success.response.statusCode, 429);
      expect(success.value, isA<GetAnAlbumResponse429>());

      final value = success.value as GetAnAlbumResponse429;
      expect(value.body, isA<TooManyRequestsBodyModel>());
      expect(value.body.error, isA<ErrorObject>());
      expect(value.body.error.status, isA<int>());
      expect(value.body.error.message, isA<String>());
    });
  });
}
