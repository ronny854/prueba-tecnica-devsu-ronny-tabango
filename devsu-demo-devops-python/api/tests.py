import json
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APITestCase
from .models import User
from .serializers import UserSerializer


class TestUserModel(TestCase):
    """Tests for the User model"""

    def setUp(self):
        self.user = User.objects.create(name='ModelTest', dni='11111111111')

    def test_user_str_representation(self):
        """Test the string representation of User model"""
        self.assertEqual(str(self.user), 'ModelTest')

    def test_user_creation(self):
        """Test user is created correctly"""
        self.assertEqual(self.user.name, 'ModelTest')
        self.assertEqual(self.user.dni, '11111111111')

    def test_user_dni_max_length(self):
        """Test dni field max length"""
        max_length = self.user._meta.get_field('dni').max_length
        self.assertEqual(max_length, 13)

    def test_user_name_max_length(self):
        """Test name field max length"""
        max_length = self.user._meta.get_field('name').max_length
        self.assertEqual(max_length, 30)


class TestUserSerializer(TestCase):
    """Tests for the User serializer"""

    def setUp(self):
        self.user = User.objects.create(name='SerializerTest', dni='22222222222')
        self.serializer = UserSerializer(instance=self.user)

    def test_serializer_contains_expected_fields(self):
        """Test serializer has expected fields"""
        data = self.serializer.data
        self.assertCountEqual(data.keys(), ['id', 'dni', 'name'])

    def test_serializer_data_content(self):
        """Test serializer data is correct"""
        data = self.serializer.data
        self.assertEqual(data['name'], 'SerializerTest')
        self.assertEqual(data['dni'], '22222222222')

    def test_serializer_valid_data(self):
        """Test serializer with valid data"""
        valid_data = {'name': 'NewUser', 'dni': '33333333333'}
        serializer = UserSerializer(data=valid_data)
        self.assertTrue(serializer.is_valid())

    def test_serializer_invalid_data_missing_name(self):
        """Test serializer with missing name"""
        invalid_data = {'dni': '44444444444'}
        serializer = UserSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('name', serializer.errors)

    def test_serializer_invalid_data_missing_dni(self):
        """Test serializer with missing dni"""
        invalid_data = {'name': 'NoDoc'}
        serializer = UserSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('dni', serializer.errors)


class TestHealthEndpoint(APITestCase):
    """Tests for the health check endpoint"""

    def test_health_endpoint_returns_ok(self):
        """Test health endpoint returns status ok"""
        response = self.client.get('/api/health/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.content), {"status": "ok"})


class TestUserView(APITestCase):
    """Tests for the User API views"""

    def setUp(self):
        self.user = User.objects.create(name='Test1', dni='09876543210')
        self.url = reverse("users-list")
        self.data = {'name': 'Test2', 'dni': '09876543211'}

    def test_post_create_user(self):
        """Test creating a new user via POST"""
        response = self.client.post(self.url, self.data, format='json')
        self.assertEqual(response.status_code, 201)
        content = json.loads(response.content)
        self.assertEqual(content['name'], 'Test2')
        self.assertEqual(content['dni'], '09876543211')
        self.assertEqual(User.objects.count(), 2)

    def test_post_duplicate_dni_returns_error(self):
        """Test creating user with duplicate DNI returns error"""
        duplicate_data = {'name': 'Duplicate', 'dni': '09876543210'}
        response = self.client.post(self.url, duplicate_data, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertEqual(json.loads(response.content), {'detail': 'User already exists'})
        self.assertEqual(User.objects.count(), 1)

    def test_post_invalid_data_missing_fields(self):
        """Test creating user with missing required fields"""
        invalid_data = {'name': 'OnlyName'}
        response = self.client.post(self.url, invalid_data, format='json')
        self.assertEqual(response.status_code, 400)

    def test_get_list_users(self):
        """Test getting list of all users"""
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(json.loads(response.content)), 1)

    def test_get_list_multiple_users(self):
        """Test getting list with multiple users"""
        User.objects.create(name='Test2', dni='11111111111')
        User.objects.create(name='Test3', dni='22222222222')
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(json.loads(response.content)), 3)

    def test_get_single_user(self):
        """Test retrieving a single user by ID"""
        response = self.client.get(f'{self.url}{self.user.id}/')
        self.assertEqual(response.status_code, 200)
        content = json.loads(response.content)
        self.assertEqual(content['name'], 'Test1')
        self.assertEqual(content['dni'], '09876543210')

    def test_get_nonexistent_user_returns_404(self):
        """Test retrieving non-existent user returns 404"""
        response = self.client.get(f'{self.url}9999/')
        self.assertEqual(response.status_code, 404)

    def test_put_update_user(self):
        """Test updating user via PUT"""
        update_data = {'name': 'Updated', 'dni': '99999999999'}
        response = self.client.put(f'{self.url}{self.user.id}/', update_data, format='json')
        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.name, 'Updated')
        self.assertEqual(self.user.dni, '99999999999')

    def test_patch_partial_update_user(self):
        """Test partial update user via PATCH"""
        patch_data = {'name': 'PartialUpdate'}
        response = self.client.patch(f'{self.url}{self.user.id}/', patch_data, format='json')
        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.name, 'PartialUpdate')
        self.assertEqual(self.user.dni, '09876543210')

    def test_delete_user(self):
        """Test deleting a user"""
        response = self.client.delete(f'{self.url}{self.user.id}/')
        self.assertEqual(response.status_code, 204)
        self.assertEqual(User.objects.count(), 0)

    def test_delete_nonexistent_user_returns_404(self):
        """Test deleting non-existent user returns 404"""
        response = self.client.delete(f'{self.url}9999/')
        self.assertEqual(response.status_code, 404)