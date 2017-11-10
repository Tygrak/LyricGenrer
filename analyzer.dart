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
    print("Loaded data from ${totalsongs} songs from ${words["Total Albums"]["All"]} albums, split into ${words.length} genres.\n");
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
  } else{
    if (args.length >= 1) {
      print("Genre ${args.join(" ")} not found.");
    }
    genreName = "Power Metal";
  }
  //String genreName = "Heavy Metal";
  //String genreName = "Rock";
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
    if (wordsContain[genreName][word] < 5 || wordsContain[genreName][word] == totalContains[word] || genreWords[word] < max(1, totalwords/10000) || word.contains("") || word.contains("�") || word.length < 2){
      continue;
    }
    tfIdfWords.add(word);
    tfIdfValues.add(CalculateTFIDFNormalized(genreWords[word], totalContains[word], wordsContain[genreName][word], genreSongs, totalwords));
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