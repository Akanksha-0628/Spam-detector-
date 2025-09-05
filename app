import streamlit as st
import pickle
import string
import nltk
from nltk.corpus import stopwords
from nltk.stem.porter import PorterStemmer
import json
import os

# =========================
# Spam Detector Setup
# =========================
ps = PorterStemmer()

def transform_text(text):
    text = text.lower()
    text = nltk.word_tokenize(text)

    # Remove non-alphanumeric
    y = [i for i in text if i.isalnum()]
    # Remove stopwords and punctuation
    y = [i for i in y if i not in stopwords.words('english') and i not in string.punctuation]
    # Stemming
    y = [ps.stem(i) for i in y]

    return " ".join(y)

# Load vectorizer and trained model
tfidf = pickle.load(open('vectorizer.pkl', 'rb'))
model = pickle.load(open('model.pkl', 'rb'))

# =========================
# Authentication Setup
# =========================
USER_FILE = "users.json"

# Load existing users
if os.path.exists(USER_FILE):
    with open(USER_FILE, "r") as f:
        users = json.load(f)
else:
    users = {}

# Save users to file
def save_users():
    with open(USER_FILE, "w") as f:
        json.dump(users, f)

# =========================
# Navigation State
# =========================
if "logged_in" not in st.session_state:
    st.session_state.logged_in = False
if "username" not in st.session_state:
    st.session_state.username = ""

# =========================
# Signup Page
# =========================
def signup():
    st.title("Sign Up")
    username = st.text_input("Create Username")
    password = st.text_input("Create Password", type="password")
    confirm_password = st.text_input("Confirm Password", type="password")

    if st.button("Sign Up"):
        if password != confirm_password:
            st.error("Passwords do not match!")
        elif username in users:
            st.error("Username already exists!")
        elif username.strip() == "" or password.strip() == "":
            st.error("Username and password cannot be empty!")
        else:
            # Save new user
            users[username] = password
            save_users()
            st.success("Sign-Up Successful! Redirecting to Spam Detector...")

            # Auto login after signup
            st.session_state.logged_in = True
            st.session_state.username = username
            st.rerun()  # immediately redirect

# =========================
# Login Page
# =========================
def login():
    st.title("Login")
    username = st.text_input("Username")
    password = st.text_input("Password", type="password")

    if st.button("Login"):
        if username in users and users[username] == password:
            st.session_state.logged_in = True
            st.session_state.username = username
            st.rerun()
        else:
            st.error("Invalid username or password")

# =========================
# Spam Detection Page
# =========================
def spam_detector():
    st.title(f"Welcome, {st.session_state.username}!")
    st.header("Email/SMS Spam Classifier")

    input_sms = st.text_area("Enter the message")

    if st.button('Predict'):
        # 1. Preprocess
        transformed_sms = transform_text(input_sms)

        # 2. Vectorize
        vector_input = tfidf.transform([transformed_sms]).toarray()

        # 3. Predict
        result = model.predict(vector_input)[0]

        # 4. Display
        if result == 1:
            st.header("Spam 🚨")
        else:
            st.header("Not Spam ✅")

    # Logout Button
    if st.button("Logout"):
        st.session_state.logged_in = False
        st.session_state.username = ""
        st.rerun()

# =========================
# Main Navigation
# =========================
if not st.session_state.logged_in:
    # Only show login/signup when not logged in
    menu = st.sidebar.radio("Navigation", ["Login", "Sign Up"])
    if menu == "Sign Up":
        signup()
    else:
        login()
else:
    # Show spam detection page when logged in
    spam_detector()
