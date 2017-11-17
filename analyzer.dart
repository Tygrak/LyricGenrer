import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:collection';

int totalsongs;
Map<String, Map<String, int>> words;
Map<String, Map<String, int>> wordsContain;
Map<String, int> totalGenreWords;
Map<String, int> totalContains;
int amount;
int columnSpaces;
int lineColumns;
bool resultDetailed = true;

main (List<String> args) async{
  List<String> argsC = new List.from(args);
  if (argsC.contains("-a")){
    amount = int.parse(argsC[argsC.indexOf("-a")+1]);
    argsC.removeAt(argsC.indexOf("-a")+1);
    argsC.removeAt(argsC.indexOf("-a"));
  }
  if (argsC.contains("-num")){
    amount = int.parse(argsC[argsC.indexOf("-num")+1]);
    argsC.removeAt(argsC.indexOf("-num")+1);
    argsC.removeAt(argsC.indexOf("-num"));
  }
  if (argsC.contains("-detailed")){
    resultDetailed = true;
    argsC.removeAt(argsC.indexOf("-detailed"));
  }
  if (argsC.contains("-undetailed")){
    resultDetailed = false;
    argsC.removeAt(argsC.indexOf("-undetailed"));
  }
  if (argsC.contains("-nodetail")){
    resultDetailed = false;
    argsC.removeAt(argsC.indexOf("-nodetail"));
  }
  if (argsC.contains("-nodetails")){
    resultDetailed = false;
    argsC.removeAt(argsC.indexOf("-nodetails"));
  }
  if (argsC.contains("-space")){
    columnSpaces = int.parse(argsC[argsC.indexOf("-space")+1]);
    argsC.removeAt(argsC.indexOf("-space")+1);
    argsC.removeAt(argsC.indexOf("-space"));
  }
  if (argsC.contains("-spaces")){
    columnSpaces = int.parse(argsC[argsC.indexOf("-spaces")+1]);
    argsC.removeAt(argsC.indexOf("-spaces")+1);
    argsC.removeAt(argsC.indexOf("-spaces"));
  }
  if (argsC.contains("-columns")){
    lineColumns = int.parse(argsC[argsC.indexOf("-columns")+1]);
    argsC.removeAt(argsC.indexOf("-columns")+1);
    argsC.removeAt(argsC.indexOf("-columns"));
  }
  if (argsC.contains("-perrow")){
    lineColumns = int.parse(argsC[argsC.indexOf("-perrow")+1]);
    argsC.removeAt(argsC.indexOf("-perrow")+1);
    argsC.removeAt(argsC.indexOf("-perrow"));
  }
  words = new Map<String, Map<String, int>>();
  wordsContain = new Map<String, Map<String, int>>();
  {
    File outputFile = new File("words.json");
    File outputContainFile = new File("wordscontain.json");
    words = JSON.decode(outputFile.readAsStringSync());
    wordsContain = JSON.decode(outputContainFile.readAsStringSync());
    totalsongs = words["Total Songs"]["All"];
    List<String> toRemove = new List<String>();
    int removeUnder = 2;
    int removeUnderSongs = 5;
    if (argsC.contains("-removeunder")){
      removeUnder = int.parse(argsC[argsC.indexOf("-removeunder")+1]);
      argsC.removeAt(argsC.indexOf("-removeunder")+1);
      argsC.removeAt(argsC.indexOf("-removeunder"));
    }
    if (argsC.contains("-minalbums")){
      removeUnder = int.parse(argsC[argsC.indexOf("-minalbums")+1]);
      argsC.removeAt(argsC.indexOf("-minalbums")+1);
      argsC.removeAt(argsC.indexOf("-minalbums"));
    }
    if (argsC.contains("-minsongs")){
      removeUnderSongs = int.parse(argsC[argsC.indexOf("-minsongs")+1]);
      argsC.removeAt(argsC.indexOf("-minsongs")+1);
      argsC.removeAt(argsC.indexOf("-minsongs"));
    }
    for (String genre in words["Total Albums"].keys){
      if (words["Total Albums"][genre] <= removeUnder-1 && !toRemove.contains(genre)){
        toRemove.add(genre);
      }
    }
    for (String genre in words["Total Songs"].keys){
      if (words["Total Songs"][genre] <= removeUnderSongs-1 && !toRemove.contains(genre)){
        toRemove.add(genre);
      }
    }
    for (int i = 0; i < toRemove.length; i++){
      words["Total Albums"].remove(toRemove[i]);
      words["Total Songs"].remove(toRemove[i]);
      wordsContain.remove(toRemove[i]);
      words.remove(toRemove[i]);
    }
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
  if (argsC.length >= 1 && words.containsKey(argsC.join(" "))){
    genreName = argsC.join(" ");
  } else if (argsC.length >= 1 && (argsC[0].toLowerCase() == "genres" || argsC[0].toLowerCase() == "genre")){
    print("Genres:");
    int i = (lineColumns == null ? 2 : lineColumns);
    String line = "";
    String contains = "";
    if (argsC.length > 1){
      contains = argsC[1].toLowerCase();
    }
    for (String word in words["Total Songs"].keys) {
      if (word.toLowerCase().contains(contains)){
        i--;
        if (i == 0){
          line += word.trim();
        } else if (columnSpaces != null && columnSpaces < 1){
          line += word.trim() + " ";
        } else{
          line += word.trim().padRight((columnSpaces == null ? 42 : columnSpaces));
        }
      } else{
        continue;
      }
      if (i == 0){
        i = (lineColumns == null ? 2 : lineColumns);
        print(line);
        line = "";
        continue;
      }
    }
    return;
  } else if (argsC.length >= 1 && (argsC[0].toLowerCase() == "genresongs" || argsC[0].toLowerCase() == "genredetailed")){
    print("Genres Songs:");
    int i = (lineColumns == null ? 2 : lineColumns);
    String line = "";
    String contains = "";
    if (argsC.length > 1){
      contains = argsC[1].toLowerCase();
    }
    words["Total Songs"] = SortMapFromHighest(words["Total Songs"]);
    words["Total Songs"] = ReverseMap(words["Total Songs"]);
    Map<String, int> genresSelected = new Map<String, int>();
    int pos = 0;
    if (contains != ""){
      for (String word in words["Total Songs"].keys) {
        if (word.toLowerCase().contains(contains)){
          genresSelected[word] = words["Total Songs"][word];
        }
      }
    } else{
      genresSelected = words["Total Songs"];
    }
    int maxAmount = (amount == null ? 1000 : amount)+1;
    if (genresSelected.keys.length < maxAmount){
      maxAmount = genresSelected.keys.length;
    }
    int j = maxAmount;
    for (String word in genresSelected.keys) {
      pos++;
      if (pos <= genresSelected.keys.length-maxAmount+1){
        continue;
      }
      if (word.toLowerCase().contains(contains)){
        j--;
        /*if (j == 0){
          print(line);
          break;
        }*/
        i--;
        if (i == 0){
          line += "${j.toString().padLeft(amount.toString().length)}. ${word.trim()} - ${genresSelected[word]} - ${words["Total Albums"][word]}";
        } else if (columnSpaces != null && columnSpaces < 1){
          line += "${j.toString().padLeft(amount.toString().length)}. ${word.trim()} - ${genresSelected[word]} - ${words["Total Albums"][word]} ";
        } else{
          line += "${j.toString().padLeft(amount.toString().length)}. ${word.trim()} - ${genresSelected[word]} - ${words["Total Albums"][word]} ".padRight((columnSpaces == null ? 42 : columnSpaces));
        }
      } else{
        continue;
      }
      if (i == 0){
        i = (lineColumns == null ? 2 : lineColumns);
        print(line);
        line = "";
        continue;
      }
    }
    return;
  } else if (argsC.length >= 1 && (argsC[0].toLowerCase() == "word" || argsC[0].toLowerCase() == "words")){
    print("Words:\n");
    for (var i = 1; i < argsC.length; i++) {
      Map<String, double> wordGenreTFIDF = CalculateWordGenres(argsC[i].toLowerCase());
      wordGenreTFIDF = SortMapFromHighest(wordGenreTFIDF);
      wordGenreTFIDF = NormalizeMapValues(wordGenreTFIDF);
      print("${argsC[i].toLowerCase()}:");
      int j = 0;
      String toPrint = "";
      for (var genre in wordGenreTFIDF.keys) {
        if (resultDetailed){
          toPrint = " ${(j+1).toString().padLeft(amount.toString().length)}. : $genre > ${wordGenreTFIDF[genre]}\n" + toPrint;
        } else{
          toPrint = " ${(j+1).toString().padLeft(amount.toString().length)}. : $genre\n" + toPrint;
        }
        j++;
        if (j == (amount == null ? 9 : amount)){
          print(toPrint);
          break;
        }
      }
    }
    return;
  } else if (argsC.length >= 1 && (argsC[0].toLowerCase() == "similarity" || argsC[0].toLowerCase() == "similar")){
    print("Cosine similarity of genres:\n");
    if (argsC.length < 3){
      print("Not enough arguments supplied to calculate similarity.");
      return;
    }
    String genre1 = "";
    String genre2 = "";
    bool firstGenre = true;
    for (var i = 1; i < argsC.length; i++) {
      if (argsC[i] == "-" || argsC[i] == ":"){
        firstGenre = false;
        continue;
      }
      if (firstGenre){
        genre1 += argsC[i]+" ";
      } else{
        genre2 += argsC[i]+" ";
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
  } else if (argsC.length >= 1 && (argsC[0].toLowerCase() == "getsimilar" || argsC[0].toLowerCase() == "similargenres")){
    print("Similar genres:\n");
    if (argsC.length < 2){
      print("Not enough arguments supplied to calculate similar genres.");
      return;
    }
    String genre1 = "";
    for (var i = 1; i < argsC.length; i++) {
      genre1 += argsC[i]+" ";
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
    similaritys = SortMapFromHighest(similaritys);
    print("$genre1:");
    int j = 0;
    String toPrint = "";
    for (var genre in similaritys.keys){
      if (resultDetailed){
        toPrint = " ${(j+1).toString().padLeft(amount.toString().length)}. : $genre > ${similaritys[genre]}\n" + toPrint;
      } else{
        toPrint = " ${(j+1).toString().padLeft(amount.toString().length)}. : $genre\n" + toPrint;
      }
      j++;
      if (j == (amount == null ? 9 : amount)){
        print(toPrint);
        break;
      }
    }
    return;
  } else if (argsC.length >= 1 && (argsC[0].toLowerCase() == "groups" || argsC[0].toLowerCase() == "genregroups")){
    print("Genre groups:\n");
    int perGenre = 1;
    if (argsC.length > 1){
      perGenre = int.parse(argsC[1]);
      print("Top $perGenre for each genre added to group.");
    }
    Map<String, Map<String, double>> similaritys = new Map<String, Map<String, double>>();
    Map<String, Map<String, double>> tfidfs = new Map<String, Map<String, double>>();
    for (var genre in words.keys){
      if (genre == "Total Songs" || genre == "Total Albums") continue;
      tfidfs[genre] = CalculateGenreTFIDF(genre);
    }
    for (var genre1 in words.keys){
      if (genre1 == "Total Songs" || genre1 == "Total Albums") continue;
      Map<String, double> genre1tfidfs = tfidfs[genre1];
      similaritys[genre1] = new Map<String, double>();
      for (var genre2 in words.keys){
        if (genre2 == genre1 || genre2 == "Total Songs" || genre2 == "Total Albums") continue;
        Map<String, double> genre2tfidfs = tfidfs[genre2];
        similaritys[genre1][genre2] = CosineSimilarity(genre1tfidfs, genre2tfidfs);
        if (!similaritys[genre1][genre2].isFinite){
          similaritys[genre1][genre2] = 0.0;
        }
      }
      similaritys[genre1] = SortMapFromHighest(similaritys[genre1]);
      //print("$genre1 : ${similaritys[genre1].keys.first}");
    }
    List<List<String>> groups = new List<List<String>>();
    for (var genre1 in similaritys.keys){
      int j = perGenre;
      for (var genre2 in similaritys[genre1].keys){
        bool flag = false;
        for (var i = 0; i < groups.length; i++){
          if (groups[i].contains(genre1) && !groups[i].contains(genre2)){
            groups[i].add(genre2);
            flag = true;
            break;
          } else if (groups[i].contains(genre2) && !groups[i].contains(genre1)){
            groups[i].add(genre1);
            flag = true;
            break;
          } else if (groups[i].contains(genre2) && groups[i].contains(genre1)){
            flag = true;
            break;
          }
        }
        if (!flag){
          List<String> newGroup = new List<String>();
          newGroup.add(genre1);
          newGroup.add(genre2);
          groups.add(newGroup);
        }
        j--;
        if (j == 0){
          break;
        }
      }
    }
    for (var i = 0; i < groups.length; i++){
      print(groups[i]);
    }
    return;
  } else if (argsC.length >= 1 && (argsC[0].toLowerCase() == "textimportant" || argsC[0].toLowerCase() == "texttfidf")){
    print("Text important:\n");
    if (argsC.length < 2){
      print("Not enough arguments - a text file has to be supplied.");
      return;
    }
    File textfile = new File(argsC[1]);
    if (!textfile.existsSync()){
      print("File ${argsC[1]} not found.");
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
    texttfidfs = SortMapFromHighest(texttfidfs);
    print("${argsC[1]} most important words:");
    int j = 0;
    String toPrint = "";
    for (var word in texttfidfs.keys){
      if (resultDetailed){
        toPrint = " ${(j+1).toString().padLeft(amount.toString().length)}. : $word > ${texttfidfs[word]}\n" + toPrint;
      } else{
        toPrint = " ${(j+1).toString().padLeft(amount.toString().length)}. : $word\n" + toPrint;
      }
      j++;
      if (j == (amount == null ? 50 : amount) || j == texttfidfs.keys.length-1){
        print(toPrint);
        break;
      }
    }
    return;
  } else if (argsC.length >= 1 && (argsC[0].toLowerCase() == "textgenre" || argsC[0].toLowerCase() == "text")){
    print("Text genre:\n");
    if (argsC.length < 2){
      print("Not enough arguments - a text file has to be supplied.");
      return;
    }
    File textfile = new File(argsC[1]);
    if (!textfile.existsSync()){
      print("File ${argsC[1]} not found.");
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
    similaritys = SortMapFromHighest(similaritys);
    print("${argsC[1]} most probable genres:");
    int j = 0;
    String toPrint = "";
    for (var genre in similaritys.keys){
      if (resultDetailed){
        toPrint = " ${(j+1).toString().padLeft(amount.toString().length)}. : $genre > ${similaritys[genre].toStringAsFixed(5)}\n" + toPrint;
      } else{
        toPrint = " ${(j+1).toString().padLeft(amount.toString().length)}. : $genre\n" + toPrint;
      }
      j++;
      if (j == (amount == null ? 9 : amount)){
        print(toPrint);
        break;
      }
    }
    return;
  } else{
    if (argsC.length >= 1){
      print("Genre ${argsC.join(" ")} not found.");
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
  for (var i = min((amount == null ? 98 : amount-1), tfIdfWords.length-1); i >= 0; i--){
    if (resultDetailed){
      print("${(i+1).toString().padLeft(amount.toString().length)}. : ${tfIdfWords[i]} > ${tfIdfValues[i].toStringAsFixed(8)} (${genreWords[tfIdfWords[i]]}, ${wordsContain[genreName][tfIdfWords[i]]}, ${totalContains[tfIdfWords[i]]})");
    } else{
      print("${(i+1).toString().padLeft(amount.toString().length)}. ${tfIdfWords[i]}");
    }
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

Map SortMapFromHighest(Map toSort){
  var sortedKeys = toSort.keys.toList(growable:false)..sort((k1, k2) => toSort[k1].compareTo(toSort[k2]));
  sortedKeys = sortedKeys.reversed;
  LinkedHashMap sortedMap = new LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => toSort[k]);
  return sortedMap;
}

Map ReverseMap(Map toReverse){
  var sortedKeys = toReverse.keys.toList(growable:false);
  sortedKeys = sortedKeys.reversed;
  LinkedHashMap sortedMap = new LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => toReverse[k]);
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