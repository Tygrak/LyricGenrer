# LyricGenrer
A lyric scraping bot and data analyzer.

# Command line commands
| Command | Argument | Description  |
|---|---|---|
| Default | Genrename | Prints the most important words for the genre. |
| genres | (optional) String | Prints all available genres, if provided with a string prints only genres containing the string. |
| genresongs | (optional) String | Prints all available genres and the number of songs and albums in the dataset, if provided with a string prints only genres containing the string. |
| word | String | Prints the genres for which the word is the most important. |
| similarity | Genrename1 : Genrename2 | Prints the similarity of two genres. |
| getsimilar | Genrename | Prints the most similar genres to the genre. |
| texttfidf | Textfile Name | Prints the most important words for the text from the textfile. |
| text | Textfile Name | Prints the most similar genres to the text from the textfile. |

# Command line arguments
| Argument | Description  |
|---|---|
| -a (int) | Amount of printed results from the command. |
| -minalbums (int) | Ignores genres from the dataset with less than the chosen amount of albums. |
| -minsongs (int) | Ignores genres from the dataset with less than the chosen amount of songs. |
| -nodetail | Commands don't show additional details - for example tfidf values. |
| -space (int) | Amount of spaces between columns for the commands genres and genresongs. |
| -columns (int) | Amount of columns per line for the commands genres and genresongs. |

# Examples
```dart analyzer.dart Death Metal``` : Prints the most important words for Death Metal.

```dart analyzer.dart genresongs -spaces 40 -columns 5``` : Shows all genres split into 5 columns, divided by 40 spaces.

```dart analyzer.dart genresongs Metal -minalbums 10``` : Shows all genres containing the word metal with more than 10 albums.

```dart analyzer.dart getsimilar Doom Metal -a 20``` : Prints the 20 most similar genres to Doom Metal.

```dart analyzer.dart text text.txt``` : Prints the most similar genres to the text from the textfile text.txt.