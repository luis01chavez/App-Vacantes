import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vacantes/api_service.dart';
import 'package:vacantes/models/job_offer.dart';
import 'job_detail_screen.dart'; // Asegúrate de importar la nueva pantalla

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
  Set<int> viewedJobs = {}; // Mantiene el seguimiento de los empleos vistos
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchJobOffers();
  }

  Future<void> _fetchJobOffers() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole');
    final userId = prefs.getString('userId');

    setState(() {
      userRole = role;
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas de Empleo'),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollEndNotification &&
              scrollNotification.metrics.extentAfter == 0 &&
              !_isLoading &&
              _hasMore) {
            _loadMoreJobOffers();
          }
          return false;
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : displayedJobOffers.isEmpty
                ? Center(
                    child: Text(
                      userRole == 'admin'
                          ? 'No hay publicaciones de empleos activas.'
                          : 'Lo sentimos, por el momento no tenemos empleos disponibles en tu municipio',
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
