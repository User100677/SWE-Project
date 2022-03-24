import 'package:danger_zone_alert/news/article_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:news_api_flutter_package/model/article.dart';
import 'package:news_api_flutter_package/model/error.dart';
import 'package:news_api_flutter_package/news_api_flutter_package.dart';
import 'custom_dailog_route.dart';

class ArticleList extends StatelessWidget {
  final NewsAPI _newsAPI = NewsAPI("434b5638ed034f98a296145d4e2a7462");

  ArticleList({Key? key}) : super(key: key);

  @override
  Widget build( BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: _buildAppBar(),

        body: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Center(
        child:Text(
          "News",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,

          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      children: [
        _buildEverythingTabView(),
      ],
    );
  }



  Widget _buildEverythingTabView() {
    return FutureBuilder<List<Article>>(
        future: _newsAPI.getEverything(query:"crime", domains:"thestar.com.my"),
        builder: (BuildContext context, AsyncSnapshot<List<Article>> snapshot) {
          return snapshot.connectionState == ConnectionState.done
              ? snapshot.hasData
              ? _buildArticleListView(snapshot.data!)
              : _buildError(snapshot.error as ApiError)
              : _buildProgress();
        });
  }

  Widget _buildArticleListView(List<Article> articles) {
    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (context, index) {
        Article article = articles[index];
        return InkWell(
          child: GestureDetector(
            onTap: ()  {
              Navigator.of(context).push(HeroDialogRoute(builder:(context) => Center(
                  child: ArticlePage(article: article))
              ));
            },
            child: Card(
              child: ListTile(
                title: Text(article.title!, maxLines: 2),
                subtitle: Text(article.description ?? "", maxLines: 2),
                trailing: article.urlToImage == null
                    ? null
                    : Image.network(article.urlToImage!),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildProgress() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(ApiError error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error.code ?? "",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(error.message!, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}