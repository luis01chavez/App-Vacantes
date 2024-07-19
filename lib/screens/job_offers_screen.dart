import 'package:flutter/material.dart';

class JobOffersScreen extends StatelessWidget {
  const JobOffersScreen({super.key});

  final List<JobOffer> jobOffers = const [
    JobOffer(
      companyName: 'Empresa A',
      jobDescription: 'Empresa importante en x cosa solicita (x) numero de empleados',
    ),
    JobOffer(
      companyName: 'Company B',
      jobDescription: 'Empresa importante en x cosa solicita (x) numero de empleados',
    ),
    // Add more job offers here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas de Empleo'),
      ),
      body: ListView.builder(
        itemCount: jobOffers.length,
        itemBuilder: (context, index) {
          return JobOfferCard(jobOffer: jobOffers[index]);
        },
      ),
    );
  }
}

class JobOffer {
  final String companyName;
  final String jobDescription;

  const JobOffer({
    required this.companyName,
    required this.jobDescription,
  });
}

class JobOfferCard extends StatelessWidget {
  final JobOffer jobOffer;

  const JobOfferCard({super.key, required this.jobOffer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10.0),
      child: ListTile(
        title: Text(jobOffer.companyName),
        subtitle: Text(jobOffer.jobDescription),
      ),
    );
  }
}
