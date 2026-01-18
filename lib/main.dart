import 'package:flutter/material.dart';
import 'Modele/redacteur.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color.fromARGB(255, 103, 58, 183)),
      ),
      home: const MyHomePage(title: 'Gestion des redacteurs'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build (BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor : Colors.deepPurple,
        title: const Text('Gestion des rédacteurs', style:TextStyle(color: Colors.white),),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white,),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white,),
            onPressed: () {},
          ),
        ],
      ),
      body: RedacteurInterface(),
    );
  }
}


class RedacteurInterface extends StatefulWidget {
  const RedacteurInterface({super.key});

  @override
  State<RedacteurInterface> createState() => _RedacteurInterfaceState();
}

class _RedacteurInterfaceState extends State<RedacteurInterface> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  late Future<void> _initializeDbFuture;
  late Future<List<Redacteur>> _redacteursFuture;

  @override
  void initState() {
    super.initState();
    _initializeDbFuture = DatabaseManager().initialize();
    _redacteursFuture = DatabaseManager().getAllRedacteurs();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeDbFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        } else {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 20.0),
                TextField(
                  controller: _prenomController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                ),
                const SizedBox(height: 20.0),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton.icon(
                  onPressed: () {
                    String nom = _nomController.text;
                    String email = _emailController.text;
                    String prenom = _prenomController.text;

                    Redacteur redacteur = Redacteur.withoutId(
                      nom: nom,
                      prenom: prenom,
                      email: email,
                    );

                    DatabaseManager().insertRedacteur(redacteur).then((_) {
                      if (!context.mounted) return; //On verifie d'abord si le widget est toujours present.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rédacteur ajouté avec succès !'),
                          backgroundColor: Colors.deepPurple,
                          behavior: SnackBarBehavior.floating, // Pour qu'elle "flotte" au-dessus du bas
                          shape: RoundedRectangleBorder( // Arrondir les coins
                            borderRadius: BorderRadius.circular(10),
                          )
                        ),
                      );

                      _nomController.clear();
                      _prenomController.clear();
                      _emailController.clear();

                      setState(() {
                        _redacteursFuture = DatabaseManager().getAllRedacteurs();
                      });
                    }).catchError((error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de l\'ajout du rédacteur: $error'),
                        ),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Ajouter un Rédacteur', style:TextStyle(color: Colors.white),),
                ),
                const SizedBox(height: 20.0),
                Expanded(
                  child: FutureBuilder<List<Redacteur>>(
                    future: _redacteursFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Erreur : ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Aucun rédacteur trouvé.'));
                      } else {
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final redacteur = snapshot.data![index];
                            return ListTile(
                              title: Text('${redacteur.nom} ${redacteur.prenom}'),
                              subtitle: Text(redacteur.email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Supprimer le rédacteur'),
                                            content: const Text('Êtes-vous sûr de vouloir supprimer ce rédacteur ?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Annuler'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  DatabaseManager().deleteRedacteur(redacteur.id!).then((_) {
                                                    setState(() {
                                                      _redacteursFuture = DatabaseManager().getAllRedacteurs();
                                                    });
                                                    if (!context.mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Rédacteur supprimé avec succès !'),
                                                        backgroundColor: Colors.deepPurple,
                                                        behavior: SnackBarBehavior.floating, // Pour qu'elle "flotte" au-dessus du bas
                                                        shape: RoundedRectangleBorder( // Arrondir les coins
                                                          borderRadius: BorderRadius.circular(10),
                                                        )
                                                      ),
                                                    );
                                                    if (!context.mounted) return;
                                                    Navigator.of(context).pop(); // Fermer la boîte de dialogue
                                                  }).catchError((error) {
                                                    if (!context.mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Erreur lors de la suppression du rédacteur: $error'),
                                                      ),
                                                    );
                                                  });
                                                },
                                                child: const Text('Supprimer',style: TextStyle(color: Colors.pink)),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                    onPressed: () {
                                      _nomController.text = redacteur.nom;
                                      _prenomController.text = redacteur.prenom;
                                      _emailController.text = redacteur.email;

                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Modifier le rédacteur'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: _nomController,
                                                  decoration: const InputDecoration(labelText: 'Nom'),
                                                ),
                                                TextField(
                                                  controller: _prenomController,
                                                  decoration: const InputDecoration(labelText: 'Prénom'),
                                                ),
                                                TextField(
                                                  controller: _emailController,
                                                  decoration: const InputDecoration(labelText: 'Email'),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  _nomController.clear();
                                                  _prenomController.clear();
                                                  _emailController.clear();
                                                },
                                                child: const Text('Annuler',style: TextStyle(color: Colors.pink)),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  String nom = _nomController.text;
                                                  String prenom = _prenomController.text;
                                                  String email = _emailController.text;

                                                  Redacteur redacteurModifie = Redacteur(
                                                    id: redacteur.id,
                                                    nom: nom,
                                                    prenom: prenom,
                                                    email: email,
                                                  );

                                                  DatabaseManager().updateRedacteur(redacteurModifie).then((_) {
                                                    setState(() {
                                                      _redacteursFuture = DatabaseManager().getAllRedacteurs();
                                                    });
                                                    if (!context.mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Rédacteur modifié avec succès !'),
                                                        backgroundColor: Colors.deepPurple,
                                                        behavior: SnackBarBehavior.floating, // Pour qu'elle "flotte" au-dessus du bas
                                                        shape: RoundedRectangleBorder( // Arrondir les coins
                                                          borderRadius: BorderRadius.circular(10),
                                                        )
                                                      ),
                                                    );
                                                    Navigator.of(context).pop();
                                                    // Fermer la boîte de dialogue
                                                    _nomController.clear();
                                                    _prenomController.clear();
                                                    _emailController.clear();
                                                  }).catchError((error) {
                                                    if (!context.mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Erreur lors de la modification du rédacteur: $error'),
                                                      ),
                                                    );
                                                  });
                                                },
                                                child: const Text('Modifier', style: TextStyle(color: Colors.deepPurple)),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),

                                ],
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}