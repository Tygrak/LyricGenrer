import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:collection';

int totalsongs;
Map<String, Map<String, int>> words;
Map<String, Map<String, int>> wordsContain;
Map<String, int> totalGenreWords;
Map<String, int> totalContains;

main (List<String> args) async{
  words = new Map<String, Map<String, int>>();
  wordsContain = new Map<String, Map<String, int>>();
  {
    File outputFile = new File("words.json");
    File outputContainFile = new File("wordscontain.json");
    words = JSON.decode(outputFile.readAsStringSync());
    wordsContain = JSON.decode(outputContainFile.readAsStringSync());
    totalsongs = words["Total Songs"]["All"];
    print("Loaded data from ${totalsongs} songs from ${words["Total Albums"]["All"]} albums, split into ${words.length} genres.\n");
  }
  totalGenreWords = new Map<String, int>();
  for (String genre in words.keys){
    for (String word in words[genre].keys){
      if (totalGenreWords.containsKey(genre)){
        totalGenreWords[genre] += words[genre][word];
      } else{
        totalGenreWords[genre] = words[genre][word];
      }
    }
  }
  totalContains = new Map<String, int>();
  for (String genre in wordsContain.keys){
    for (String word in wordsContain[genre].keys){
      if (totalContains.containsKey(word)){
        totalContains[word] += wordsContain[genre][word];
      } else{
        totalContains[word] = wordsContain[genre][word];
      }
    }
  }
  String genreName;
  if (args.length >= 1 && words.containsKey(args.join(" "))){
    genreName = args.join(" ");
  } else if (args[0].toLowerCase() == "genres" || args[0].toLowerCase() == "genre"){
    print("Genres:");
    int i = 2;
    String line = "";
    String contains = "";
    if (args.length > 1){
      contains = args[1].toLowerCase();
    }
    for (String word in words["Total Songs"].keys) {
      if (word.toLowerCase().contains(contains)){
        line += word;
        i--;
      } else{
        continue;
      }
      if (i == 0){
        i = 2;
        print(line);
        line = "";
        continue;
      }
      for (var j = word.length; j < 42; j++) {
        line += " ";
      }
    }
    return;
  } else if (args[0].toLowerCase() == "word" || args[0].toLowerCase() == "words"){
    print("Words:\n");
    for (var i = 1; i < args.length; i++) {
      Map<String, double> wordGenreTFIDF = CalculateWordGenres(args[i].toLowerCase());
      wordGenreTFIDF = SortByTFIDF(wordGenreTFIDF);
      print("${args[i].toLowerCase()}:");
      int j = 0;
      String toPrint = "";
      for (var genre in wordGenreTFIDF.keys) {
        toPrint = " ${(j+1).toString().length >= 2 ? ((j+1).toString()) : (" "+(j+1).toString())}. : $genre > ${wordGenreTFIDF[genre]}\n" + toPrint;
        j++;
        if (j == 9){
          print(toPrint);
          break;
        }
      }
    }
    return;
  } else{
    if (args.length >= 1) {
      print("Genre ${args.join(" ")} not found.");
    }
    genreName = "Power Metal";
  }
  Map<String, int> genreWords = words[genreName];
  int genreSongs = words["Total Songs"][genreName];
  List<String> tfIdfWords = new List<String>();
  List<double> tfIdfValues = new List<double>();
  print("Results for $genreName:");
  print("Using data from ${totalGenreWords[genreName]} words from ${words["Total Songs"][genreName]} songs from ${words["Total Albums"][genreName]} albums.");
  for (String word in genreWords.keys){
    if (wordsContain[genreName][word] < 5 || wordsContain[genreName][word] == totalContains[word] || genreWords[word] < max(1, totalGenreWords[genreName]/10000) || word.contains("") || word.contains("�") || word.length < 2){
      continue;
    }
    tfIdfWords.add(word);
    tfIdfValues.add(CalculateTFIDFNormalized(genreWords[word], totalContains[word], wordsContain[genreName][word], genreSongs, totalGenreWords[genreName]));
  }
  while (true){
    bool flag = true;
    for (var i = 0; i < tfIdfValues.length; i++) {
      if (i+1 < tfIdfValues.length && tfIdfValues[i+1] > tfIdfValues[i]){
        double tmp = tfIdfValues[i+1];
        String stmp = tfIdfWords[i+1];
        tfIdfValues[i+1] = tfIdfValues[i];
        tfIdfValues[i] = tmp;
        tfIdfWords[i+1] = tfIdfWords[i];
        tfIdfWords[i] = stmp;
        flag = false;
      }
    }
    if (flag){
      break;
    }
  }
  tfIdfValues = NormalizeValues(tfIdfValues);
  for (var i = min(98, tfIdfWords.length-1); i >= 0; i--){
    print("${(i+1).toString().length >= 2 ? ((i+1).toString()) : (" "+(i+1).toString())}. : ${tfIdfWords[i]} > ${tfIdfValues[i].toStringAsFixed(8)} (${genreWords[tfIdfWords[i]]}, ${wordsContain[genreName][tfIdfWords[i]]}, ${totalContains[tfIdfWords[i]]})");
  }
}

double CalculateTFIDF(int termFrequency, int documentFrequency){
  num tf = termFrequency;
  num idf = totalsongs/(documentFrequency+1);
  return tf*idf;
}

double CalculateTFIDFNormalized(int termFrequency, int documentFrequency, int songFrequency, int genreSongs, int totalWords){
  //num tf = -log((termFrequency/totalWords)*10000);
  //num idf = log(totalsongs/(documentFrequency+1));
  //double tf = (totalWords/termFrequency) * (genreSongs/songFrequency);
  double tf = pow(termFrequency/totalWords, 1) * pow(songFrequency/genreSongs, 1);
  double idf = pow(1/(documentFrequency/(totalsongs)), 2);
  /*num tf = -log((termFrequency/totalWords)*1000);
  num idf = log(totalsongs/(documentFrequency+1));*/
  return tf*idf;
}

double CalculateTFIDFMod(int termFrequency, int documentFrequency, int songFrequency, int genreSongs, int totalWords){
  if (termFrequency == null) termFrequency = 0;
  if (documentFrequency == null) documentFrequency = 0;
  if (songFrequency == null) songFrequency = 0;
  double tf = pow(termFrequency/totalWords, 1) * pow(songFrequency/genreSongs, 1);
  double idf = pow(1/(documentFrequency/(totalsongs)), 2);
  return tf*idf;
}

List<double> NormalizeValues(List<double> values){
  double max = values[0];
  for (var i = 1; i < values.length; i++) {
    if (values[i] > max){
      max = values[i];
    }
  }
  for (var i = 0; i < values.length; i++) {
    values[i] = values[i]/max;
  }
  return values;
}

Map<String, double> CalculateWordGenres(String word){
  Map<String, double> genretfidf = new Map<String, double>();
  for (String genre in wordsContain.keys){
    genretfidf[genre] = CalculateTFIDFMod(words[genre][word], totalContains[word], wordsContain[genre][word], words["Total Songs"][genre], totalGenreWords[genre]);
  }
  return genretfidf;
}

Map SortByTFIDF(Map tfidfs){
  var sortedKeys = tfidfs.keys.toList(growable:false)..sort((k1, k2) => tfidfs[k1].compareTo(tfidfs[k2]));
  sortedKeys = sortedKeys.reversed;
  LinkedHashMap sortedMap = new LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => tfidfs[k]);
  return sortedMap;
}

String GetHighestTFIDF(Map<String, double> tfidfs){
  String max;
  for (String genre in tfidfs.keys){
    if (max == null || tfidfs[genre] > tfidfs[max]){
      max = genre;
    }
  }
  return max;
}