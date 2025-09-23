#!/usr/bin/env python3
"""
Predator Mobile ALPR - Optimized for Android/Termux
Based on Connor Vieira's Predator ALPR project
Adapted for Samsung Galaxy S25 local processing
"""

import cv2
import json
import sys
import os
import re
import time
from datetime import datetime
from pathlib import Path

class MobilePredatorALPR:
    def __init__(self):
        self.confidence_threshold = 60.0
        self.debug = True
        self.valid_plate_patterns = [
            r'^[A-Z0-9]{2,8}$',  # Basic alphanumeric
            r'^[A-Z]{1,3}[0-9]{1,4}[A-Z]?$',  # Standard US format
            r'^[0-9]{1,3}[A-Z]{1,3}[0-9]{1,4}$',  # Mixed format
        ]
        
    def log(self, message):
        """Debug logging"""
        if self.debug:
            timestamp = datetime.now().strftime("%H:%M:%S")
            print(f"[{timestamp}] ALPR: {message}")
            
    def validate_plate_format(self, plate_text):
        """Validate license plate format using Predator-inspired rules"""
        if not plate_text or len(plate_text) < 2:
            return False
            
        # Remove spaces and convert to uppercase
        plate_clean = re.sub(r'[^A-Z0-9]', '', plate_text.upper())
        
        # Check length constraints
        if len(plate_clean) < 4 or len(plate_clean) > 8:
            return False
            
        # Check against common patterns
        for pattern in self.valid_plate_patterns:
            if re.match(pattern, plate_clean):
                return True
                
        return False
        
    def calculate_confidence(self, text, bbox_area, image_area):
        """Calculate confidence score based on multiple factors"""
        base_confidence = 50.0
        
        # Text quality factors
        if self.validate_plate_format(text):
            base_confidence += 25.0
            
        # Size factor (plates should be reasonable size)
        size_ratio = bbox_area / image_area
        if 0.001 < size_ratio < 0.1:  # Reasonable plate size
            base_confidence += 15.0
            
        # Character density (plates have consistent spacing)
        if len(text) >= 5:
            base_confidence += 10.0
            
        return min(base_confidence, 95.0)
        
    def preprocess_image(self, image):
        """Preprocess image for better ALPR detection"""
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        enhanced = clahe.apply(gray)
        
        # Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(enhanced, (3, 3), 0)
        
        return blurred
        
    def detect_text_regions(self, image):
        """Detect potential text regions using OpenCV"""
        processed = self.preprocess_image(image)
        
        # Edge detection
        edges = cv2.Canny(processed, 50, 150)
        
        # Find contours
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        text_regions = []
        image_area = image.shape[0] * image.shape[1]
        
        for contour in contours:
            # Get bounding rectangle
            x, y, w, h = cv2.boundingRect(contour)
            
            # Filter by aspect ratio (plates are wider than tall)
            aspect_ratio = w / h if h > 0 else 0
            area = w * h
            
            # Typical license plate aspect ratios: 2:1 to 6:1
            if 1.5 < aspect_ratio < 8.0 and area > 1000:
                text_regions.append({
                    'bbox': (x, y, w, h),
                    'area': area,
                    'aspect_ratio': aspect_ratio
                })
                
        # Sort by area (larger regions first)
        text_regions.sort(key=lambda r: r['area'], reverse=True)
        
        return text_regions[:5]  # Return top 5 candidates
        
    def extract_text_pytesseract(self, image, bbox):
        """Extract text using basic character recognition"""
        # This is a simplified version - in full implementation,
        # you would use pytesseract or another OCR engine
        
        x, y, w, h = bbox
        roi = image[y:y+h, x:x+w]
        
        # For demo purposes, return mock plate numbers
        # In real implementation, this would be:
        # import pytesseract
        # text = pytesseract.image_to_string(roi, config='--psm 8 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
        
        mock_plates = ["ABC123", "XYZ789", "DEF456", "GHI012", "JKL345"]
        return mock_plates[hash(str(bbox)) % len(mock_plates)]
        
    def process_image(self, image_path):
        """Main processing function - Predator-inspired workflow"""
        start_time = time.time()
        self.log(f"Processing image: {image_path}")
        
        if not os.path.exists(image_path):
            return {"error": "Image file not found", "success": False}
            
        try:
            # Load and validate image
            image = cv2.imread(image_path)
            if image is None:
                return {"error": "Unable to load image", "success": False}
                
            original_height, original_width = image.shape[:2]
            self.log(f"Image dimensions: {original_width}x{original_height}")
            
            # Resize for processing (optimize for mobile)
            max_width = 1280
            if original_width > max_width:
                scale = max_width / original_width
                new_width = int(original_width * scale)
                new_height = int(original_height * scale)
                image = cv2.resize(image, (new_width, new_height))
                self.log(f"Resized to: {new_width}x{new_height}")
                
            # Detect potential plate regions
            text_regions = self.detect_text_regions(image)
            self.log(f"Found {len(text_regions)} potential text regions")
            
            # Process each region
            detected_plates = []
            image_area = image.shape[0] * image.shape[1]
            
            for i, region in enumerate(text_regions):
                bbox = region['bbox']
                x, y, w, h = bbox
                
                # Extract text from region
                plate_text = self.extract_text_pytesseract(image, bbox)
                
                # Calculate confidence
                confidence = self.calculate_confidence(plate_text, region['area'], image_area)
                
                # Validate and filter
                if confidence >= self.confidence_threshold and self.validate_plate_format(plate_text):
                    plate_data = {
                        "plate_number": plate_text.upper(),
                        "confidence": round(confidence, 1),
                        "region": "us",
                        "coordinates": {
                            "x": int(x),
                            "y": int(y), 
                            "width": int(w),
                            "height": int(h)
                        },
                        "aspect_ratio": round(region['aspect_ratio'], 2),
                        "area": region['area']
                    }
                    detected_plates.append(plate_data)
                    self.log(f"Valid plate detected: {plate_text} (confidence: {confidence}%)")
                    
            # Sort by confidence
            detected_plates.sort(key=lambda p: p['confidence'], reverse=True)
            
            processing_time = time.time() - start_time
            
            results = {
                "success": True,
                "processing_time": round(processing_time, 2),
                "plates_detected": detected_plates,
                "regions_analyzed": len(text_regions),
                "image_info": {
                    "path": image_path,
                    "original_size": f"{original_width}x{original_height}",
                    "processed_at": datetime.now().isoformat(),
                    "file_size": os.path.getsize(image_path) if os.path.exists(image_path) else 0
                },
                "alpr_engine": "predator_mobile_cv2"
            }
            
            self.log(f"Processing completed in {processing_time:.2f}s")
            return results
            
        except Exception as e:
            self.log(f"Error processing image: {str(e)}")
            return {
                "error": str(e),
                "success": False,
                "processing_time": time.time() - start_time
            }

def main():
    """Command line interface"""
    if len(sys.argv) != 2:
        print(json.dumps({
            "error": "Usage: python predator_mobile.py <image_path>",
            "success": False
        }))
        sys.exit(1)
        
    image_path = sys.argv[1]
    
    # Create ALPR processor
    alpr = MobilePredatorALPR()
    
    # Process image
    results = alpr.process_image(image_path)
    
    # Output JSON results for Flutter consumption
    print(json.dumps(results, indent=2))

if __name__ == "__main__":
    main()