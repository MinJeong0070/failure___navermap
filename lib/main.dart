import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// 메인 함수에서 지도 초기화하기
void main() async {
  // Flutter 프레임워크가 위젯 바인딩을 초기화하도록 보장
  WidgetsFlutterBinding.ensureInitialized();
  // NaverMapSdk 인스턴스를 초기화하고 클라이언트 ID를 설정
  await NaverMapSdk.instance.initialize(
    clientId: 'd896acbaw3', // 클라이언트 ID 설정
    onAuthFailed: (ex) { // 인증 실패 시 콜백 함수
      debugPrint("네이버 지도 인증 오류: $ex");
    },
  );
  // MyApp 위젯 실행
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NaverMapScreen(), // NaverMapScreen 위젯을 홈 화면으로 설정
    );
  }
}

class NaverMapScreen extends StatefulWidget {
  const NaverMapScreen({Key? key});

  @override
  State<NaverMapScreen> createState() => NaverMapScreenState();
}

class NaverMapScreenState extends State<NaverMapScreen> {
  late Position CurrentPosition; // 현재 위치 저장할 변수
  bool locationButtonEnable = false; // 위치가 가져와졌는지 여부를 나타내는 변수

  // 전국 8도 마커 위치 리스트
  final List<NLatLng> locations = const [
    NLatLng(37.2872, 127.0119), // 경기도
    NLatLng(37.6575, 128.6723), // 강원도
    NLatLng(36.6717, 126.648), // 충청남도
    NLatLng(36.9947, 127.6778), // 충청북도
    NLatLng(35.8175, 127.152), // 전라북도
    NLatLng(34.7983, 126.9702), // 전라남도
    NLatLng(36.4822, 128.8337), // 경상북도
    NLatLng(35.1455, 129.0365), // 경상남도
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 현재 위치 가져오기 함수 호출
  }

  // 현재 위치를 가져오는 함수
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high); // 높은 정확도로 현재 위치 가져오기
    setState(() {
      CurrentPosition = position; // 가져온 위치를 상태 변수에 저장
      locationButtonEnable = true; // 위치가 가져와졌음을 표시
    });
  }

  // 날씨 정보를 가져오는 함수
  static Future<String> getWeather(double lat, double lon,
      {http.Client? client}) async {
    client ??= http.Client();
    const apiKey = '26c869ae3ac58f39aba492117839a153'; // OpenWeatherMap API 키
    final response = await client.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric')); // 날씨 API 호출

    if (response.statusCode == 200) {
      var data = json.decode(response.body); // 응답 데이터 디코딩
      return '${data['weather'][0]['description']}, ${data['main']['temp']}°C'; // 날씨 정보 반환
    } else {
      throw Exception('Failed to load weather data'); // 오류 발생 시 예외 던지기
    }
  }

  // 마커를 생성하는 함수
  Set<NMarker> buildMarkers() {
    return locations.asMap().entries.map((entry) {
      int index = entry.key;
      NLatLng location = entry.value;
      var marker = NMarker(
        id: 'marker_${location.latitude}_${location.longitude}', // 마커 ID 설정
        position: location, // 마커 위치 설정
        caption: NOverlayCaption(text: 'Location $index'), // 마커 캡션 설정
      );
      // 마커 탭 시 날씨 정보를 표시하는 리스너 설정
      marker.setOnTapListener((overlay) async {
        var weather = await getWeather(location.latitude, location.longitude); // 날씨 정보 가져오기
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: Text('Weather: $weather'), // 날씨 정보 다이얼로그로 표시
              );
            },
          );
        }
      });
      return marker;
    }).toSet(); // 마커를 Set으로 반환
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: locationButtonEnable
          ? NaverMap(
        options: NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: NLatLng(
                CurrentPosition.latitude, CurrentPosition.longitude), // 초기 카메라 위치 설정
            zoom: 15, // 초기 줌 레벨 설정
          ),
        ),
        onMapReady: (NaverMapController controller) {
          controller.addOverlayAll(buildMarkers()); // 지도 준비 완료 시 마커 추가
        },
      )
          : const Center(child: CircularProgressIndicator()), // 위치를 가져오는 중일 때 로딩 표시
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Position>('CurrentPosition', CurrentPosition));
    properties.add(DiagnosticsProperty<bool>('locationButtonEnable', locationButtonEnable));
  }
}

