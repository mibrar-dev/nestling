import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart'
    as assets;

/// Asset paths for the token-colourable UI icons.
///
/// Every value forwards to [assets.NestlingIcons] (the single source of
/// truth); every icon is a 24x24 line SVG using `currentColor`, tinted at the
/// call site through [NestIcon].
abstract final class NestIcons {
  const new _();

  static const String back = assets.NestlingIcons.back;
  static const String close = assets.NestlingIcons.close;
  static const String plus = assets.NestlingIcons.plus;
  static const String edit = assets.NestlingIcons.edit;
  static const String eye = assets.NestlingIcons.eye;
  static const String lock = assets.NestlingIcons.lock;
  static const String backspace = assets.NestlingIcons.backspace;
  static const String search = assets.NestlingIcons.search;
  static const String arrowRight = assets.NestlingIcons.arrowRight;
  static const String home = assets.NestlingIcons.home;
  static const String quests = assets.NestlingIcons.quests;
  static const String money = assets.NestlingIcons.money;
  static const String family = assets.NestlingIcons.family;
  static const String check = assets.NestlingIcons.check;
  static const String circle = assets.NestlingIcons.circle;
  static const String bed = assets.NestlingIcons.bed;
  static const String bedSit = assets.NestlingIcons.bedSit;
  static const String table = assets.NestlingIcons.table;
  static const String dishwasher = assets.NestlingIcons.dishwasher;
  static const String hoover = assets.NestlingIcons.hoover;
  static const String bin = assets.NestlingIcons.bin;
  static const String basket = assets.NestlingIcons.basket;
  static const String questBed = assets.NestlingIcons.questBed;
  static const String questDishes = assets.NestlingIcons.questDishes;
  static const String questHoover = assets.NestlingIcons.questHoover;
  static const String questBins = assets.NestlingIcons.questBins;
  static const String book = assets.NestlingIcons.book;
  static const String bookOpen = assets.NestlingIcons.bookOpen;
  static const String paw = assets.NestlingIcons.paw;
  static const String sprout = assets.NestlingIcons.sprout;
  static const String schoolBag = assets.NestlingIcons.schoolBag;
  static const String washingMachine = assets.NestlingIcons.washingMachine;
  static const String questCard = assets.NestlingIcons.questCard;
  static const String sleep = assets.NestlingIcons.sleep;
  static const String noAds = assets.NestlingIcons.noAds;
  static const String person = assets.NestlingIcons.person;
  static const String pinUk = assets.NestlingIcons.pinUk;
  static const String shieldCheck = assets.NestlingIcons.shieldCheck;
  static const String target = assets.NestlingIcons.target;
  static const String trash = assets.NestlingIcons.trash;
  static const String poundCoin = assets.NestlingIcons.poundCoin;
  static const String ribbon = assets.NestlingIcons.ribbon;
  static const String gift = assets.NestlingIcons.gift;
  static const String saved = assets.NestlingIcons.saved;
  static const String screenTime = assets.NestlingIcons.screenTime;
  static const String film = assets.NestlingIcons.film;
  static const String filmStrip = assets.NestlingIcons.filmStrip;
  static const String clock = assets.NestlingIcons.clock;
  static const String moon = assets.NestlingIcons.moon;
  static const String chefHat = assets.NestlingIcons.chefHat;
  static const String cafe = assets.NestlingIcons.cafe;
  static const String lamp = assets.NestlingIcons.lamp;
  static const String pizza = assets.NestlingIcons.pizza;
  static const String rewardTv = assets.NestlingIcons.rewardTv;
  static const String rewardFilm = assets.NestlingIcons.rewardFilm;
  static const String rewardMoon = assets.NestlingIcons.rewardMoon;
  static const String rewardCake = assets.NestlingIcons.rewardCake;
  static const String rewardCoffee = assets.NestlingIcons.rewardCoffee;
  static const String rewardPlate = assets.NestlingIcons.rewardPlate;
  static const String bag = assets.NestlingIcons.bag;
  static const String phone = assets.NestlingIcons.phone;
  static const String coinSparkle = assets.NestlingIcons.coinSparkle;
  static const String heart = assets.NestlingIcons.heart;
  static const String heartOutline = assets.NestlingIcons.heartOutline;
  static const String pipFace = assets.NestlingIcons.pipFace;
  static const String jar = assets.NestlingIcons.jar;
  static const String feedBowl = assets.NestlingIcons.feedBowl;
  static const String ball = assets.NestlingIcons.ball;
  static const String bubbles = assets.NestlingIcons.bubbles;
  static const String scarf = assets.NestlingIcons.scarf;
  static const String sunHat = assets.NestlingIcons.sunHat;
  static const String wellies = assets.NestlingIcons.wellies;
  static const String crown = assets.NestlingIcons.crown;
  static const String wardrobeScarf = assets.NestlingIcons.wardrobeScarf;
  static const String wardrobeWellies = assets.NestlingIcons.wardrobeWellies;
}

/// Token-colourable SVG icon.
///
/// Wraps `SvgPicture.asset` with a `ColorFilter.srcIn` tint so line icons
/// follow the palette. Illustrations (Pip, coin, badges) keep their own
/// colours — render those with `SvgPicture.asset` directly.
class NestIcon extends StatelessWidget {
  const new(
    this.assetName, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final String assetName;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tint = color;
    // SizedBox pins the icon to [size]: inside tight parents (e.g. a 40px
    // tile) an SvgPicture would otherwise scale up to fill and overflow.
    return SizedBox.square(
      dimension: size,
      child: SvgPicture.asset(
        assetName,
        width: size,
        height: size,
        colorFilter: tint == null
            ? null
            : ColorFilter.mode(tint, BlendMode.srcIn),
        semanticsLabel: semanticLabel,
      ),
    );
  }
}
