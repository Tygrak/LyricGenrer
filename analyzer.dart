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
  } else if (args[0].toLowerCase() == "similarity" || args[0].toLowerCase() == "similar"){
    print("Cosine similarity of genres:\n");
    if (args.length < 3){
      print("Not enough arguments supplied to calculate similarity.");
      return;
    }
    String genre1 = "";
    String genre2 = "";
    bool firstGenre = true;
    for (var i = 1; i < args.length; i++) {
      if (args[i] == "-" || args[i] == ":"){
        firstGenre = false;
        continue;
      }
      if (firstGenre){
        genre1 += args[i]+" ";
      } else{
        genre2 += args[i]+" ";
      }
    }
    genre1 = genre1.trim();
    genre2 = genre2.trim();
    if (!words.containsKey(genre1)){
      print("Genre ${genre1} not found.");
      return;
    }
    if (!words.containsKey(genre2)){
      print("Genre ${genre2} not found.");
      return;
    }
    Map<String, double> genre1tfidfs = CalculateGenreTFIDF(genre1);
    Map<String, double> genre2tfidfs = CalculateGenreTFIDF(genre2);
    double similarity = CosineSimilarity(genre1tfidfs, genre2tfidfs);
    print("$genre1 : $genre2 > $similarity");
    return;
  } else if (args[0].toLowerCase() == "getsimilar" || args[0].toLowerCase() == "similargenres"){
    print("Similar genres:\n");
    if (args.length < 2){
      print("Not enough arguments supplied to calculate similar genres.");
      return;
    }
    String genre1 = "";
    for (var i = 1; i < args.length; i++) {
      genre1 += args[i]+" ";
    }
    genre1 = genre1.trim();
    if (!words.containsKey(genre1)){
      print("Genre ${genre1} not found.");
      return;
    }
    Map<String, double> similaritys = new Map<String, double>();
    Map<String, double> genre1tfidfs = CalculateGenreTFIDF(genre1);
    for (var genre2 in words.keys){
      if (genre2 == genre1 || genre2 == "Total Songs" || genre2 == "Total Albums") continue;
      Map<String, double> genre2tfidfs = CalculateGenreTFIDF(genre2);
      similaritys[genre2] = CosineSimilarity(genre1tfidfs, genre2tfidfs);
      if (!similaritys[genre2].isFinite){
        similaritys[genre2] = 0.0;
      }
    }
    similaritys = SortByTFIDF(similaritys);
    print("$genre1:");
    int j = 0;
    String toPrint = "";
    for (var genre in similaritys.keys){
      toPrint = " ${(j+1).toString().length >= 2 ? ((j+1).toString()) : (" "+(j+1).toString())}. : $genre > ${similaritys[genre]}\n" + toPrint;
      j++;
      if (j == 9){
        print(toPrint);
        break;
      }
    }
    return;
  } else if (args[0].toLowerCase() == "textimportant" || args[0].toLowerCase() == "texttfidf"){
    print("Text important:\n");
    if (args.length < 2){
      print("Not enough arguments - a text file has to be supplied.");
      return;
    }
    File textfile = new File(args[1]);
    if (!textfile.existsSync()){
      print("File ${args[1]} not found.");
      return;
    }
    String text = textfile.readAsStringSync();
    text = text.replaceAll(new RegExp("[\"?!,.:}{)()]"), "");
    text = text.replaceAll("\n", " ");
    text = text.toLowerCase();
    List<String> textWords = text.split(" ");
    Map<String, int> textCounts = new Map<String, int>();
    for (var i = 0; i < textWords.length; i++){
      if (textCounts.containsKey(textWords[i])){
        textCounts[textWords[i]]++;
      } else{
        textCounts[textWords[i]] = 1;
      }
    }
    Map<String, double> texttfidfs = CalculateTextTFIDF(textCounts);
    texttfidfs = NormalizeMapValues(texttfidfs);
    texttfidfs = SortByTFIDF(texttfidfs);
    print("${args[1]} most important words:");
    int j = 0;
    String toPrint = "";
    for (var word in texttfidfs.keys){
      toPrint = " ${(j+1).toString().length >= 2 ? ((j+1).toString()) : (" "+(j+1).toString())}. : $word > ${texttfidfs[word]}\n" + toPrint;
      j++;
      if (j == 50 || j == texttfidfs.keys.length-1){
        print(toPrint);
        break;
      }
    }
    return;
  } else if (args[0].toLowerCase() == "textgenre" || args[0].toLowerCase() == "text"){
    print("Text genre:\n");
    if (args.length < 2){
      print("Not enough arguments - a text file has to be supplied.");
      return;
    }
    File textfile = new File(args[1]);
    if (!textfile.existsSync()){
      print("File ${args[1]} not found.");
      return;
    }
    String text = textfile.readAsStringSync();
    text = text.replaceAll(new RegExp("[\"?!,.:}{)()];"), "");
    text = text.replaceAll("\n", " ");
    text = text.toLowerCase();
    List<String> textWords = text.split(" ");
    Map<String, int> textCounts = new Map<String, int>();
    for (var i = 0; i < textWords.length; i++){
      if (textCounts.containsKey(textWords[i])){
        textCounts[textWords[i]]++;
      } else{
        textCounts[textWords[i]] = 1;
      }
    }
    Map<String, double> similaritys = new Map<String, double>();
    Map<String, double> texttfidfs = CalculateTextTFIDF(textCounts);
    texttfidfs = NormalizeMapValues(texttfidfs);
    for (var genre2 in words.keys){
      if (genre2 == "Total Songs" || genre2 == "Total Albums") continue;
      Map<String, double> genre2tfidfs = CalculateGenreTFIDF(genre2);
      genre2tfidfs = NormalizeMapValues(genre2tfidfs);
      similaritys[genre2] = TextSimilarity(texttfidfs, genre2tfidfs);
      if (!similaritys[genre2].isFinite){
        similaritys[genre2] = 0.0;
      }
    }
    similaritys = SortByTFIDF(similaritys);
    print("${args[1]} most probable genres:");
    int j = 0;
    String toPrint = "";
    for (var genre in similaritys.keys){
      toPrint = " ${(j+1).toString().length >= 2 ? ((j+1).toString()) : (" "+(j+1).toString())}. : $genre > ${similaritys[genre]}\n" + toPrint;
      j++;
      if (j == 9){
        print(toPrint);
        break;
      }
    }
    return;
  } else{
    if (args.length >= 1){
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
    //print("${(i+1).toString().length >= 2 ? ((i+1).toString()) : (" "+(i+1).toString())}. ${tfIdfWords[i]}");
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
  if (documentFrequency == null) documentFrequency = 1;
  if (songFrequency == null) songFrequency = 0;
  double tf = pow(termFrequency/totalWords, 1) * pow(songFrequency/genreSongs, 1);
  double idf = pow(1/(documentFrequency/(totalsongs)), 2);
  return tf*idf;
}

double CalculateTFIDFSingle(int termFrequency, int documentFrequency, int totalWords){
  if (termFrequency == null) termFrequency = 0;
  if (documentFrequency == null) documentFrequency = 1;
  double tf = pow(termFrequency/totalWords, 1);
  double idf = log(1/(documentFrequency/(totalsongs)));
  return tf*idf;
}

List<double> NormalizeValues(List<double> values){
  double max = values[0];
  for (var i = 1; i < values.length; i++){
    if (values[i] > max){
      max = values[i];
    }
  }
  for (var i = 0; i < values.length; i++){
    values[i] = values[i]/max;
  }
  return values;
}

Map<String, double> NormalizeMapValues(Map<String, double> values){
  double max;
  for (String word in values.keys){
    if (max == null || values[word] > max){
      max = values[word];
    }
  }
  for (String word in values.keys){
    values[word] = values[word]/max;
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

Map<String, double> CalculateGenreTFIDF(String genreName){
  Map<String, double> genretfidfs = new Map<String, double>();
  for (String word in words[genreName].keys){
    if (wordsContain[genreName][word] < 5 || wordsContain[genreName][word] == totalContains[word] || words[genreName][word] < max(1, totalGenreWords[genreName]/10000) || word.contains("") || word.contains("�") || word.length < 2){
      continue;
    }
    genretfidfs[word] = CalculateTFIDFMod(words[genreName][word], totalContains[word], wordsContain[genreName][word], words["Total Songs"][genreName], totalGenreWords[genreName]);
  }
  return genretfidfs;
}

Map<String, double> CalculateTextTFIDF(Map<String, int> text){
  Map<String, double> genretfidfs = new Map<String, double>();
  int total = 0;
  for (String word in text.keys){
    total += text[word];
  }
  for (String word in text.keys){
    if (word.contains("") || word.contains("�") || word.length < 2){
      continue;
    }
    genretfidfs[word] = CalculateTFIDFSingle(text[word], totalContains[word], total);
  }
  return genretfidfs;
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

double CosineSimilarity(Map<String, double> tfidf1, Map<String, double> tfidf2){
  for (var key in tfidf1.keys) {
    if (!tfidf2.containsKey(key)){
      tfidf2[key] = 0.0;
    }
  }
  for (var key in tfidf2.keys){
    if (!tfidf1.containsKey(key)){
      tfidf1[key] = 0.0;
    }
  }
  double dotProduct = 0.0;
  double sumA = 0.0;
  double sumB = 0.0;
  for (var key in tfidf1.keys){
    sumA += (tfidf1[key]*tfidf1[key]);
    sumB += (tfidf2[key]*tfidf2[key]);
    dotProduct += (tfidf1[key]*tfidf2[key]);
  }
  return (dotProduct/(sqrt(sumA)*sqrt(sumB)));
}

double TextSimilarity(Map<String, double> texttfidf, Map<String, double> tfidf2){
  for (var key in texttfidf.keys) {
    if (!tfidf2.containsKey(key)){
      tfidf2[key] = 0.0;
    }
  }
  double dotProduct = 0.0;
  double sumA = 0.0;
  double sumB = 0.0;
  for (var key in texttfidf.keys){
    sumA += (texttfidf[key]*texttfidf[key]);
    sumB += (tfidf2[key]*tfidf2[key]);
    dotProduct += (texttfidf[key]*tfidf2[key]);
  }
  return (dotProduct/(sqrt(sumA)*sqrt(sumB)));
}