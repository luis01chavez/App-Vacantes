import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vacantes/api_service.dart';
import 'package:vacantes/models/job_offer.dart';
import 'job_detail_screen.dart';

class JobOffersScreen extends StatefulWidget {
  const JobOffersScreen({super.key});

  @override
  JobOffersScreenState createState() => JobOffersScreenState();
}

class JobOffersScreenState extends State<JobOffersScreen> {
  List<JobOffer> allJobOffers = [];
  List<JobOffer> displayedJobOffers = [];
  final ApiService apiService = ApiService();
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  bool isUserVerified = true;
  Set<int> viewedJobs = {};
  String? userRole;
  String searchQuery = '';
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // FocusNode para la barra de búsqueda

  @override
  void initState() {
    super.initState();
    _checkUserVerification();
  }

  Future<void> _checkUserVerification() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      try {
        final userData = await apiService.getUserData(int.parse(userId));
        if (!mounted) return;
        setState(() {
          isUserVerified = userData['correoVerificado'];
          userRole = userData['rol']['nombre'];
        });
        if (isUserVerified) {
          _fetchJobOffers();
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar el usuario: $e')),
        );
      }
    }
  }

  Future<void> _fetchJobOffers() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
      _currentPage = 0;
      displayedJobOffers.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole');
    final userId = prefs.getString('userId');

    setState(() {
      userRole = role;
      isSearching = false;
    });

    try {
      List<JobOffer> fetchedJobOffers;

      if (role == 'admin') {
        fetchedJobOffers = await apiService.fetchJobOffers();
      } else {
        fetchedJobOffers = await apiService.getAvailableJobs(int.parse(userId!));
      }

      if (!mounted) return;
      setState(() {
        allJobOffers = fetchedJobOffers;
        _loadMoreJobOffers();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load job offers: $e')),
      );
    }
  }

  Future<void> _searchJobOffers(String query) async {
    setState(() {
      _isLoading = true;
      isSearching = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await apiService.searchJobOffers(query, token);

      if (!mounted) return;
      setState(() {
        allJobOffers = response;
        displayedJobOffers = allJobOffers;
        _isLoading = false;
        _hasMore = false;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar empleos: $e')),
      );
    }
  }

  void _loadMoreJobOffers() {
    if (_hasMore) {
      final nextPageOffers = allJobOffers.skip(_currentPage * _pageSize).take(_pageSize).toList();
      setState(() {
        displayedJobOffers.addAll(nextPageOffers);
        _currentPage++;
        _hasMore = nextPageOffers.length == _pageSize;
      });
    }
  }

  Future<void> _onJobTap(JobOffer jobOffer) async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('userRole');
    final userId = prefs.getString('userId');

    if (userRole == 'usuario' && userId != null && !viewedJobs.contains(jobOffer.id)) {
      try {
        await apiService.registrarVisto(int.parse(userId), jobOffer.id);
        viewedJobs.add(jobOffer.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar visto: $e')),
        );
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(jobId: jobOffer.id),
      ),
    ).then((_) {
      if (isSearching) {
        _searchJobOffers(searchQuery);
      } else {
        _fetchJobOffers();
      }
      _searchFocusNode.unfocus();
    });
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        focusNode: _searchFocusNode, 
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Buscar empleo por nombre...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          suffixIcon: isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      searchController.clear();
                      FocusScope.of(context).unfocus();
                      _fetchJobOffers();
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (searchQuery.isNotEmpty) {
                      _searchJobOffers(searchQuery);
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _searchJobOffers(value);
            FocusScope.of(context).unfocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas de Empleo'),
        bottom: userRole == 'admin'
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: _buildSearchField(),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !isUserVerified
              ? const Center(
                  child: Text(
                    'Para poder ver los empleos disponibles en tu municipio primero debes verificar tu correo electrónico en la pantalla de Perfil',
                    style: TextStyle(color: Colors.black, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollEndNotification &&
                        scrollNotification.metrics.extentAfter == 0 &&
                        !_isLoading &&
                        _hasMore) {
                      _loadMoreJobOffers();
                    }
                    return false;
                  },
                  child: displayedJobOffers.isEmpty
                      ? Center(
                          child: Text(
                            userRole == 'admin'
                                ? 'No hay publicaciones de empleos activas.'
                                : isSearching
                                    ? 'Ningún empleo disponible bajo ese nombre'
                                    : 'Lo sentimos, por el momento no tenemos empleos disponibles en tu municipio, pero sigue atento',
                            style: const TextStyle(color: Colors.black, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: displayedJobOffers.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == displayedJobOffers.length) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            return JobOfferCard(
                              jobOffer: displayedJobOffers[index],
                              onTap: () => _onJobTap(displayedJobOffers[index]),
                            );
                          },
                        ),
                ),
    );
  }
}

class JobOfferCard extends StatelessWidget {
  final JobOffer jobOffer;
  final VoidCallback onTap;

  const JobOfferCard({super.key, required this.jobOffer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jobOffer.titulo,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5.0),
              Text(
                jobOffer.descripcion,
                style: const TextStyle(
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
