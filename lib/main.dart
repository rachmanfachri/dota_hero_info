import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'DOTA Hero Stats',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _heroPageController = ScrollController();

  bool _isLoading = false;
  bool _isError = false;
  bool _isShowAll = true;
  List _selectedRoles = [];
  Map _selectedHero = {};
  List _similarHero = [];

  List<Map> _statsData = [];
  List<Map> _backupData = [];
  List _heroRoles = [];

  final List<Color> _colorPalette = const [
    Color(0xFFA72714),
    Color(0xFF8D3020),
    Color(0xFFA4230D),
    Color(0xFFAB2E17),
    Color(0xFFAC2E16),
  ];

  final Map _attributeIcon = {
    'str': 'asset/str_icon.png',
    'agi': 'asset/agi_icon.png',
    'int': 'asset/int_icon.png',
  };

  final Map _attributeName = {
    'str': 'Strength',
    'agi': 'Agility',
    'int': 'Intelligence',
  };

  @override
  void initState() {
    super.initState();
    _getHeroesData();
  }

  _getHeroesData() async {
    await http.get(Uri.parse('https://api.opendota.com/api/herostats')).then((response) {
      if (response.statusCode == 200) {
        _statsData = List.from(json.decode(response.body));
        for (var element in _statsData) {
          element['roles'].forEach(
            (role) {
              if (!_heroRoles.contains(role)) {
                _heroRoles.add(role);
              }
            },
          );
        }
      } else {
        _isError = true;
      }
      setState(() {});
    });
  }

  _appBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      title: SizedBox(
        height: kToolbarHeight - 20,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedHero.clear();
              _similarHero.clear();
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Visibility(
                visible: _selectedHero.isNotEmpty,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 5),
                  ],
                ),
              ),
              Image.asset(
                'asset/dota_logo.png',
                width: MediaQuery.of(context).size.width / 3,
                fit: BoxFit.fitWidth,
              ),
              const SizedBox(width: 10),
              const Text(
                'Hero Stats',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _filterChips() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 40,
      color: Colors.grey[900],
      padding: const EdgeInsets.all(5),
      alignment: Alignment.center,
      child: _heroRoles.isNotEmpty
          ? Row(
              children: [
                SizedBox(
                  width: 50,
                  child: ChoiceChip(
                    label: _isShowAll
                        ? Text(
                            'All',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isShowAll ? _colorPalette[1] : Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.clear,
                            size: 12,
                            color: _isShowAll ? _colorPalette[1] : Colors.white,
                          ),
                    backgroundColor: _colorPalette[1],
                    selectedColor: Colors.white,
                    selected: _isShowAll,
                    onSelected: (value) {
                      _isShowAll = value;
                      if (_isShowAll) {
                        setState(() {
                          _selectedRoles.clear();
                          _statsData = List.from(_backupData);
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _heroRoles.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          backgroundColor: _colorPalette[0],
                          selectedColor: Colors.white,
                          label: Text(
                            _heroRoles[index],
                            style: TextStyle(
                              fontSize: 12,
                              color: _selectedRoles.contains(_heroRoles[index]) ? _colorPalette[1] : Colors.white,
                            ),
                          ),
                          selected: _selectedRoles.contains(_heroRoles[index]),
                          onSelected: (bool selected) {
                            setState(
                              () {
                                _isShowAll = false;
                                !_selectedRoles.contains(_heroRoles[index])
                                    ? _selectedRoles.add(_heroRoles[index])
                                    : _selectedRoles.remove(_heroRoles[index]);
                                _filterHeroes();
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : null,
    );
  }

  _filterHeroes() {
    if (_backupData.isNotEmpty) {
      _statsData = List.from(_backupData);
      setState(() {});
    }
    if (!_isShowAll) {
      _backupData = List.from(_statsData);
      for (var e in _selectedRoles) {
        _statsData.removeWhere((element) => !element['roles'].contains(e));
      }
      setState(() {});
    }
  }

  _heroList() {
    double tileWidth = (MediaQuery.of(context).size.width / 2);

    return SizedBox(
      height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - 40,
      width: MediaQuery.of(context).size.width,
      child: GlowingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        color: _colorPalette[2],
        child: GridView.builder(
          itemCount: _statsData.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: MediaQuery.of(context).size.width / 2,
          ),
          padding: const EdgeInsets.all(10),
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedHero = Map.from(_statsData[index]);
                  _similarHeroesSort();
                });
              },
              child: Stack(
                alignment: AlignmentDirectional.topStart,
                children: [
                  Container(
                    width: tileWidth,
                    height: tileWidth * (4 / 5),
                    margin: const EdgeInsets.all(10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: 'https://api.opendota.com' + _statsData[index]['img'],
                            width: tileWidth,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 12,
                              width: 12,
                              child: CachedNetworkImage(
                                imageUrl: 'https://api.opendota.com' + _statsData[index]['icon'],
                                height: 12,
                                fit: BoxFit.fitHeight,
                                progressIndicatorBuilder: (context, url, downloadProgress) =>
                                    CircularProgressIndicator(value: downloadProgress.progress),
                                errorWidget: (context, url, error) => const SizedBox(),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: tileWidth - 12),
                              child: Text(
                                ' ' + _statsData[index]['localized_name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[200],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2.5),
                        Text(
                          (_statsData[index]['roles']).join(', '),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(_attributeIcon[_statsData[index]['primary_attr']]),
                        Text(
                          ' ' + _attributeName[_statsData[index]['primary_attr']],
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _heroPage() {
    return SizedBox(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: _selectedHero.isNotEmpty ? MediaQuery.of(context).size.width : 0,
          height: _selectedHero.isNotEmpty ? MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight : 0,
          color: Colors.grey[850],
          child: _selectedHero.isNotEmpty
              ? GlowingOverscrollIndicator(
                  axisDirection: AxisDirection.down,
                  color: _colorPalette[2],
                  child: SingleChildScrollView(
                    controller: _heroPageController,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CachedNetworkImage(
                                imageUrl: 'https://api.opendota.com' + _selectedHero['icon'],
                                height: 20,
                                fit: BoxFit.fitHeight,
                                progressIndicatorBuilder: (context, url, downloadProgress) =>
                                    CircularProgressIndicator(value: downloadProgress.progress),
                                errorWidget: (context, url, error) => const SizedBox(),
                              ),
                              Text(
                                ' ' + _selectedHero['localized_name'],
                                style: TextStyle(
                                  color: Colors.grey[200],
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          alignment: AlignmentDirectional.bottomStart,
                          children: [
                            CachedNetworkImage(
                              imageUrl: 'https://api.opendota.com' + _selectedHero['img'],
                              width: MediaQuery.of(context).size.width,
                              fit: BoxFit.fitWidth,
                            ),
                            Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(_attributeIcon[_selectedHero['primary_attr']]),
                                  Text(
                                    ' ' + _attributeName[_selectedHero['primary_attr']],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          (_selectedHero['roles']).join(', '),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(10),
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(5),
                                        topRight: Radius.circular(5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        const Icon(Icons.local_hospital_rounded, size: 12, color: Colors.white),
                                        Text(
                                          _selectedHero['base_health'].toString(),
                                          style: TextStyle(
                                            color: Colors.grey[200],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[700],
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(5),
                                        bottomRight: Radius.circular(5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        const Icon(Icons.science_rounded, size: 10, color: Colors.white),
                                        Text(
                                          _selectedHero['base_mana'].toString(),
                                          style: TextStyle(
                                            color: Colors.grey[200],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                children: [
                                  Text(
                                    'Atk. Type',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    ' ' + _selectedHero['attack_type'],
                                    style: TextStyle(
                                      color: Colors.grey[200],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              CachedNetworkImage(
                                imageUrl: 'https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react//heroes/stats/icon_damage.png',
                                height: 20,
                                fit: BoxFit.fitHeight,
                                progressIndicatorBuilder: (context, url, downloadProgress) =>
                                    CircularProgressIndicator(value: downloadProgress.progress),
                                errorWidget: (context, url, error) => const SizedBox(),
                              ),
                              Text(
                                ' ' + _selectedHero['base_attack_max'].toString(),
                                style: TextStyle(
                                  color: Colors.grey[200],
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              CachedNetworkImage(
                                imageUrl: 'https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react//heroes/stats/icon_movement_speed.png',
                                height: 20,
                                fit: BoxFit.fitHeight,
                                progressIndicatorBuilder: (context, url, downloadProgress) =>
                                    CircularProgressIndicator(value: downloadProgress.progress),
                                errorWidget: (context, url, error) => const SizedBox(),
                              ),
                              Text(
                                ' ' + _selectedHero['move_speed'].toString(),
                                style: TextStyle(
                                  color: Colors.grey[200],
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _similarHeroes(),
                      ],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  _similarHeroesSort() {
    _similarHero.clear();

    List data = !_isShowAll ? _backupData : _statsData;
    String attribute = _selectedHero['primary_attr'];
    List temp1 = [];

    Future.delayed(Duration.zero, () {
      for (var element in data) {
        if (element['primary_attr'] == attribute) {
          if (element['id'] != _selectedHero['id']) {
            temp1.add(element);
          }
        }
      }
    }).then((_) {
      String comparison = attribute == 'str'
          ? 'base_attack_max'
          : attribute == 'agi'
              ? 'move_speed'
              : 'base_mana';

      // now every hero in dota 2 has the same amount of base mana (so does base health)
      // so the comparison for intelligent heroes at this case is rather not useful

      temp1.sort((h2, h1) {
        return h1[comparison].compareTo(h2[comparison]);
      });
    }).then((_) {
      for (int i = 0; i < 3; i++) {
        _similarHero.add(temp1[i]);
      }
      temp1.clear();
      setState(() {});
    });
  }

  _similarHeroes() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            'Similar Heroes',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
            ),
          ),
        ),
        _similarHero.isNotEmpty
            ? SizedBox(
                height: 240,
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _similarHero.length,
                  itemBuilder: (BuildContext context, int index) {
                    return InkWell(
                      onTap: () {
                        _heroPageController.jumpTo(0);
                        setState(() {
                          _selectedHero = Map.from(_similarHero[index]);
                          _similarHeroesSort();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.only(right: 10),
                        height: 60,
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black54,
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(
                              'https://api.opendota.com' + _similarHero[index]['img'],
                            ),
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                        child: Text(
                          _similarHero[index]['localized_name'],
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            : const SizedBox(),
      ],
    );
  }

  _structure() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _filterChips(),
              _heroList(),
            ],
          ),
          _heroPage(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool pop = true;
        if (_selectedHero.isNotEmpty) {
          setState(() {
            _selectedHero.clear();
            _similarHero.clear();
          });
          pop = false;
        }
        return pop;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[800],
        appBar: _appBar(),
        body: _structure(),
      ),
    );
  }
}
