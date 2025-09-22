import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cay_sam.dart';

class PlantCard extends StatelessWidget {
  final CaySam plant;
  final VoidCallback onTap;

  PlantCard({
    required this.plant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với tên và status badge
            Padding(
              padding: EdgeInsets.all(16).copyWith(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.tenCay ?? 'Không có tên',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ID: ${plant.id}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
            ),

            // Plant Image - Full width aspect video
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: AspectRatio(
                aspectRatio: 16 / 9, // aspect-video
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1589110254547-202e8e05be49?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxnaW5zZW5nJTIwcGxhbnRzJTIwY3VsdGl2YXRpb258ZW58MXx8fHwxNzU3MTMwNTkzfDA&ixlib=rb-4.1.0&q=80&w=400',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.eco,
                            color: Colors.grey.shade600,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Plant Details
            Padding(
              padding: EdgeInsets.all(16).copyWith(top: 12),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.eco,
                    text: plant.loaiCay ?? 'Không xác định',
                  ),
                  SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    text: plant.ngayTrong != null
                        ? 'Trồng: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(plant.ngayTrong!))}'
                        : 'Chưa có ngày trồng',
                  ),
                  SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.location_on,
                    text: plant.viTri ?? 'Chưa xác định vị trí',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildStatusBadge() {
    final status = plant.trangThai ?? TrangThaiCay.khoeMauh;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}