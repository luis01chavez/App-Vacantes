import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vacantes/api_service.dart';
import 'package:vacantes/models/job_offer.dart';

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
    final userRole = prefs.getString('userRole');
    final municipioId = prefs.getString('municipioId');

    try {
      List<JobOffer> fetchedJobOffers;

      if (userRole == 'admin') {
        fetchedJobOffers = await apiService.fetchJobOffers();
      } else {
        fetchedJobOffers = await apiService.getEmpleosPorMunicipio(int.parse(municipioId!));
      }

      if (mounted) {
        setState(() {
          allJobOffers = fetchedJobOffers;
          _loadMoreJobOffers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load job offers: $e')),
        );
      }
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
            : ListView.builder(
                itemCount: displayedJobOffers.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == displayedJobOffers.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return JobOfferCard(jobOffer: displayedJobOffers[index]);
                },
              ),
      ),
    );
  }
}

class JobOfferCard extends StatelessWidget {
  final JobOffer jobOffer;

  const JobOfferCard({super.key, required this.jobOffer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10.0),
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
    );
  }
}
