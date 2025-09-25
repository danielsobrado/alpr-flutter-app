import cv2
import numpy as np
import pytesseract
import re
from PIL import Image, ImageEnhance
import logging

class RealALPR:
    def __init__(self):
        # Configure Tesseract for better license plate recognition
        self.tesseract_config = r'--oem 3 --psm 8 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        
    def preprocess_image(self, image):
        """Enhanced preprocessing for license plate images"""
        # Convert to grayscale
        if len(image.shape) == 3:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        else:
            gray = image.copy()
            
        # Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # Apply morphological operations to clean up the image
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
        morph = cv2.morphologyEx(blurred, cv2.MORPH_CLOSE, kernel)
        
        # Apply adaptive thresholding
        thresh = cv2.adaptiveThreshold(morph, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                       cv2.THRESH_BINARY, 11, 2)
        
        return thresh
    
    def find_license_plate_contours(self, image):
        """Find potential license plate regions using contour analysis"""
        # Apply edge detection
        edges = cv2.Canny(image, 50, 150, apertureSize=3)
        
        # Find contours
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        # Filter contours based on license plate characteristics
        plate_contours = []
        for contour in contours:
            # Calculate contour properties
            area = cv2.contourArea(contour)
            x, y, w, h = cv2.boundingRect(contour)
            aspect_ratio = float(w) / h if h > 0 else 0
            
            # License plate aspect ratio is typically between 2:1 and 5:1
            # and should have reasonable area
            if (2.0 <= aspect_ratio <= 6.0 and 
                area > 1000 and 
                w > 50 and h > 15):
                plate_contours.append((contour, x, y, w, h, area))
        
        # Sort by area (largest first) and return top candidates
        plate_contours.sort(key=lambda x: x[5], reverse=True)
        return plate_contours[:3]  # Top 3 candidates
    
    def extract_plate_text(self, image_region):
        """Extract text from a license plate region using OCR"""
        try:
            # Enhance the image for better OCR
            pil_image = Image.fromarray(image_region)
            
            # Increase contrast
            enhancer = ImageEnhance.Contrast(pil_image)
            pil_image = enhancer.enhance(2.0)
            
            # Increase sharpness
            enhancer = ImageEnhance.Sharpness(pil_image)
            pil_image = enhancer.enhance(2.0)
            
            # Convert back to OpenCV format
            enhanced_image = np.array(pil_image)
            
            # Apply additional preprocessing
            processed = self.preprocess_image(enhanced_image)
            
            # Resize for better OCR (height should be at least 32 pixels)
            height, width = processed.shape
            if height < 32:
                scale = 32 / height
                new_width = int(width * scale)
                processed = cv2.resize(processed, (new_width, 32), interpolation=cv2.INTER_CUBIC)
            
            # Perform OCR
            text = pytesseract.image_to_string(processed, config=self.tesseract_config)
            
            # Clean and validate the text
            cleaned_text = self.clean_plate_text(text)
            return cleaned_text
            
        except Exception as e:
            logging.error(f"OCR error: {str(e)}")
            return ""
    
    def clean_plate_text(self, text):
        """Clean and validate license plate text"""
        if not text:
            return ""
            
        # Remove whitespace and convert to uppercase
        text = text.strip().upper()
        
        # Remove non-alphanumeric characters
        text = re.sub(r'[^A-Z0-9]', '', text)
        
        # Common OCR corrections for license plates
        corrections = {
            'O': '0',  # Sometimes O is mistaken for 0
            'I': '1',  # Sometimes I is mistaken for 1
            'S': '5',  # Sometimes S is mistaken for 5
            'B': '8',  # Sometimes B is mistaken for 8
        }
        
        # Apply corrections only if it makes sense in context
        corrected_text = text
        for old, new in corrections.items():
            # Only apply if the character is surrounded by numbers
            corrected_text = re.sub(f'(?<=[0-9]){old}(?=[0-9])', new, corrected_text)
        
        # Validate plate format (basic validation)
        if len(corrected_text) >= 4 and len(corrected_text) <= 8:
            return corrected_text
        
        return text  # Return original if corrections don't help
    
    def process_image(self, image_path):
        """Main function to process an image and extract license plates"""
        try:
            # Load image
            image = cv2.imread(image_path)
            if image is None:
                return []
                
            # Resize image for processing (maintain aspect ratio)
            height, width = image.shape[:2]
            if width > 1280:
                scale = 1280 / width
                new_height = int(height * scale)
                image = cv2.resize(image, (1280, new_height), interpolation=cv2.INTER_AREA)
            
            # Convert to grayscale for processing
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Find potential license plate regions
            plate_contours = self.find_license_plate_contours(gray)
            
            results = []
            for i, (contour, x, y, w, h, area) in enumerate(plate_contours):
                # Extract the region of interest
                roi = gray[y:y+h, x:x+w]
                
                # Extract text from this region
                plate_text = self.extract_plate_text(roi)
                
                if plate_text and len(plate_text) >= 4:
                    # Calculate confidence based on text length and characteristics
                    confidence = self.calculate_confidence(plate_text, w, h, area)
                    
                    results.append({
                        'plate': plate_text,
                        'confidence': confidence,
                        'coordinates': {
                            'x1': int(x),
                            'y1': int(y), 
                            'x2': int(x + w),
                            'y2': int(y + h)
                        },
                        'matches_template': 1 if self.validate_plate_format(plate_text) else 0
                    })
            
            # Sort by confidence
            results.sort(key=lambda x: x['confidence'], reverse=True)
            return results
            
        except Exception as e:
            logging.error(f"Error processing image: {str(e)}")
            return []
    
    def calculate_confidence(self, text, width, height, area):
        """Calculate confidence score for detected plate"""
        base_confidence = 60.0
        
        # Text length bonus
        if 5 <= len(text) <= 7:
            base_confidence += 20
        elif 4 <= len(text) <= 8:
            base_confidence += 10
        
        # Aspect ratio bonus
        aspect_ratio = width / height if height > 0 else 0
        if 3.0 <= aspect_ratio <= 5.0:
            base_confidence += 15
        
        # Area bonus (reasonable sized plates)
        if area > 2000:
            base_confidence += 10
        
        # Format validation bonus
        if self.validate_plate_format(text):
            base_confidence += 15
        
        return min(base_confidence, 95.0)  # Cap at 95%
    
    def validate_plate_format(self, text):
        """Validate if text matches common license plate formats"""
        if not text or len(text) < 4:
            return False
            
        # Common patterns (can be extended)
        patterns = [
            r'^[A-Z]{3}[0-9]{3,4}$',  # ABC123, ABC1234
            r'^[0-9]{3}[A-Z]{3}$',    # 123ABC
            r'^[A-Z]{2}[0-9]{2}[A-Z]{2}$', # AB12CD
            r'^[A-Z]{1,2}[0-9]{2,4}[A-Z]{0,2}$', # Various formats
        ]
        
        for pattern in patterns:
            if re.match(pattern, text):
                return True
        
        return False

def recognize_license_plates(image_path):
    """Main function called from Flutter"""
    try:
        alpr = RealALPR()
        results = alpr.process_image(image_path)
        return results
    except Exception as e:
        logging.error(f"ALPR recognition failed: {str(e)}")
        return []