import 'dart:convert';
import 'dart:io';
import 'dart:math';

int totalsongs;

main (List<String> args) async{
  Map<String, Map<String, int>> words = new Map<String, Map<String, int>>();
  Map<String, Map<String, int>> wordsContain = new Map<String, Map<String, int>>();
  {
    File outputFile = new File("words.json");
    File outputContainFile = new File("wordscontain.json");
    words = JSON.decode(outputFile.readAsStringSync());
    wordsContain = JSON.decode(outputContainFile.readAsStringSync());
    totalsongs = words["Total Songs"]["All"];
    print("Loaded data from ${totalsongs} songs split into ${words.length} genres.\n");
  }
  //String genreName = "Power Metal"; 
  String genreName = "Hip Hop";
  Map<String, int> genreWords = words[genreName];
  Map<String, int> totalContains = new Map<String, int>();
  int genreSongs = words["Total Songs"][genreName];
  List<String> tfIdfWords = new List<String>();
  List<double> tfIdfValues = new List<double>();
  int totalwords = 0;
  for (String word in wordsContain[genreName].keys){
    totalwords += wordsContain[genreName][word];
  }
  for (String genre in wordsContain.keys){
    for (String word in wordsContain[genre].keys){
      if (totalContains.containsKey(word)){
        totalContains[word] += wordsContain[genre][word];
      } else{
        totalContains[word] = wordsContain[genre][word];
      }
    }
  }
  /*print("Genres:");
  for (String word in words["Total Songs"].keys) {
    if (word.contains("Metal") || word.contains("metal")) print(word);
  }*/
  print("Results for $genreName:");
  print("Using data from $totalwords words from ${words["Total Songs"][genreName]} songs from ${words["Total Albums"][genreName]} albums.");
  for (String word in genreWords.keys){
    if (genreWords[word] < max(1, totalwords/10000) || word.contains("") || word.contains("�") || word.length < 2){
      continue;
    }
    tfIdfWords.add(word);
    tfIdfValues.add(CalculateTFIDFNormalized(genreWords[word], totalContains[word], genreSongs, totalwords));
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
  for (var i = 98; i >= 0; i--){
    print("${i+1}. : ${tfIdfWords[i]} > ${tfIdfValues[i]} (${genreWords[tfIdfWords[i]]}, ${totalContains[tfIdfWords[i]]})");
  }
}

double CalculateTFIDF(int termFrequency, int documentFrequency){
  num tf = termFrequency;
  num idf = totalsongs/(documentFrequency+1);
  return tf*idf;
}

double CalculateTFIDFNormalized(int termFrequency, int documentFrequency, int genreSongs, int totalWords){
  //num tf = -log((termFrequency/totalWords)*100000);
  //num idf = log(totalsongs/(documentFrequency+1));
  //double tf = (termFrequency/totalWords);
  //double idf = (totalsongs/(documentFrequency+1));
  num tf = -log((termFrequency/totalWords)*10000);
  num idf = log(totalsongs/(documentFrequency+1));
  return tf*idf;
}