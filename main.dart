import 'package:dartscraper/dartscraper_io.dart';
import 'package:dartscraper/dartscraper.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

main (List<String> args) async{
  int songsStartAmount = 0;
  DateTime startTime = new DateTime.now();
  File outputFile = new File("words.json");
  File outputContainFile = new File("wordscontain.json");
  Map<String, Map<String, int>> words = new Map<String, Map<String, int>>();
  Map<String, Map<String, int>> wordsContain = new Map<String, Map<String, int>>();
  if (outputFile.existsSync() && outputContainFile.existsSync()){
    words = JSON.decode(outputFile.readAsStringSync());
    wordsContain = JSON.decode(outputContainFile.readAsStringSync());
    songsStartAmount = words["Total Songs"]["All"];
    print("Loaded data from ${words.length} genres.\n");
  } else{
    words = new Map();
    wordsContain = new Map();
    words["Total Songs"] = new Map<String, int>();
    words["Total Songs"]["All"] = 0;
    words["Total Albums"] = new Map<String, int>();
    words["Total Albums"]["All"] = 0;
  }
  String linkbase = "http://lyrics.wikia.com";
  //HtmlPage page = await GetHTML("http://lyrics.wikia.com/wiki/Category:Album?page=1");
  //HtmlPage page = await GetHTML("http://lyrics.wikia.com/wiki/Category:Genre/Power_Metal?page=1");
  //HtmlPage page = await GetHTML("http://lyrics.wikia.com/wiki/Category:Allmusic/Album?page=1");
  int startAt = 329;
  int endAt = 329;
  for (var pagenum = startAt; pagenum <= endAt; pagenum++) {
    print("Starting page $pagenum.");
    List<Future> futures = new List<Future>();
    List<String> albumLinks = new List<String>();
    //HtmlPage page = await GetHTML("http://lyrics.wikia.com/wiki/Category:Genre/Power_Metal?page=$pagenum");
    HtmlPage page = await GetHTML("http://lyrics.wikia.com/wiki/Category:Wikipedia_articles/Album?page=$pagenum");
    Tag albums = page.rootTag.GetChildWithAttributeExact("class", "mw-content-ltr", true);
    List<Tag> tags = albums.GetChildOfTypeAll("a", true);
    for (var i = 0; i < tags.length; i++){
      String link = tags[i].GetAttribute("href");
      if (link.contains("(") && link.contains(")")){
        albumLinks.add(link);
      }
    }
    for (var i = 0; i < albumLinks.length; i++) {
      try {
      HtmlPage albumpage = await GetHTML(linkbase+albumLinks[i]);
      Tag genre = albumpage.rootTag.GetChildWithAttribute("title", "Genre", true);
      if (genre == null){
        continue;
      }
      print("");
      print(linkbase+albumLinks[i] + " > " + genre.contents + ":");
      words["Total Albums"]["All"]++;
      if (words["Total Albums"].containsKey(genre.contents)){
        words["Total Albums"][genre.contents]++;
      } else{
        words["Total Albums"][genre.contents] = 1;
      }
      Map<String, int> genreWords;
      Map<String, int> genreWordsContain;
      if (words.containsKey(genre.contents)){
        genreWords = words[genre.contents];
        genreWordsContain = wordsContain[genre.contents];
      } else{
        genreWords = new Map<String, int>();
        genreWordsContain  = new Map<String, int>();
        wordsContain[genre.contents] = genreWordsContain;
        words[genre.contents] = genreWords;
        words["Total Songs"][genre.contents] = 0;
      }
      List<Tag> songlists = albumpage.rootTag.GetChildOfTypeAll("ol", true);
      List<String> visitedSongs = new List<String>();
      for (var j = 0; j < songlists.length; j++){
        List<Tag> songs = songlists[j].GetChildOfTypeAll("a", true);
        for (var k = 0; k < songs.length; k++) {
          Future GetSong() async{
            String songLink = songs[k].GetAttribute("href");
            if (songLink.contains("action=edit") || !songLink.contains(":")){
              return;
            } else if (visitedSongs.contains(songLink)){
              return;
            }
            //print(songLink + " > ");
            visitedSongs.add(songLink);
            try{
              HtmlPage songpage = await GetHTML(linkbase+songLink);
              Tag lyricsTag = songpage.rootTag.GetChildWithAttribute("class", "lyricbox", true);
              String lyrics = HtmlAsciiConvert(lyricsTag.contents);
              List<String> songWords = GetWordsFromSong(lyrics);
              List<String> songWordsContain = new List<String>();
              for (var l = 0; l < songWords.length; l++) {
                if (genreWords.containsKey(songWords[l])){
                  genreWords[songWords[l]]++;
                } else{
                  genreWords[songWords[l]] = 1;
                }
                if (!songWordsContain.contains(songWords[l])){
                  songWordsContain.add(songWords[l]);
                }
              }
              for (var l = 0; l < songWordsContain.length; l++) {
                if (genreWordsContain.containsKey(songWordsContain[l])){
                  genreWordsContain[songWordsContain[l]]++;
                } else{
                  genreWordsContain[songWordsContain[l]] = 1;
                }
              }
              print(songLink + " > Got!");
              words["Total Songs"]["All"]++;
              words["Total Songs"][genre.contents]++;
            } catch (e) {
              print("Error encountered while getting song: " + e.toString());
            }
          }
          futures.add(GetSong());
        }
      }
      }catch (e){
        print("Error encountered while getting album: " + e.toString());
      }
    }
    await Future.wait(futures);
    outputFile.writeAsStringSync(JSON.encode(words));
    outputContainFile.writeAsStringSync(JSON.encode(wordsContain));
    File lastPage = new File("lastpage.txt");
    lastPage.writeAsStringSync("$pagenum");
  }
  print("Added ${words["Total Songs"]["All"]-songsStartAmount} songs!");
  print("Operation took ${new DateTime.now().difference(startTime).inSeconds} seconds.");
  outputFile.writeAsStringSync(JSON.encode(words));
  outputContainFile.writeAsStringSync(JSON.encode(wordsContain));
}

String HtmlAsciiConvert(String text){
  text = text.replaceAll(";&#", ",");
  text = text.replaceAll("&#", "");
  text = text.replaceAll(";", "");
  text = text.replaceAll("\n", ",10,");
  if (text[0] == ","){
    text = text.replaceFirst(",", "");
  }
  List<String> codes = text.split(",");
  List<int> ncodes = new List<int>.from(codes.map((String s) => (int.parse(s, onError: (source) => 20))));
  String s;
  try {
    s = LATIN1.decode(ncodes, allowInvalid: true);
  } catch (e) {
    print("Error encountered while decoding lyrics: " + e.toString());
    return "";
  }
  return s;
}

List<String> GetWordsFromSong(String text){
  text = text.replaceAll(new RegExp("[\"?!,.:}{)()]"), "");
  text = text.replaceAll("\n", " ");
  text = text.toLowerCase();
  return text.split(" ");
}