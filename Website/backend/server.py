from json import load
import json
from flask import Flask, request
import pickle
from sklearn.preprocessing import OrdinalEncoder
from sklearn.preprocessing import LabelEncoder
import numpy as np


app = Flask(__name__)


def processInput(input: dict, encoder) -> list:
    #! Copied from predict.jsx, BE WARN for any change on either side
    options = {
        "Gender": ["Male", "Female"],
        "Home Location": ['Urban', 'Rural'],
        "Level of Education": ['Under Graduate', 'Post Graduate', 'School'],
        "Device type used to attend classes": ["Laptop", 'Desktop', 'Mobile'],
        'Economic status': ['Middle className', 'Poor', 'Rich'],
        'Are you involved in any sports?': ['No', 'Yes'],
        'Do elderly people monitor you?': ['Yes', 'No'],
        'Interested in Gaming?': ['No', 'Yes'],
        'Have separate room for studying?': ['No', 'Yes'],
        'Engaged in group studies?': ['No', 'yes'],
        'Average marks scored before pandemic in traditional classroom': ['91-100', '71-80', '81-90', '61-70', '31-40', '41-50', '21-30', '11-20', '51-60', '0-10'],
        'Interested in?': ['Practical', 'Theory', 'Both'],
        'Your level of satisfaction in Online Education': ['Average', 'Bad', 'Good'],
    }
    res = []
    marked_indices = []
    need_encode = []
    i = 0
    for k, v in input.items():
        if (k in options.keys()):
            need_encode.append(v)
            marked_indices.append(i)
        else:
            res.append(int(v))
        i += 1

    need_encode = np.array(need_encode).reshape(1, -1)
    encoded = encoder.transform(need_encode)[0]     # transform return a list for some reason

    # Insert the encoded back into input
    for i in range(0, len(encoded)):
        res.insert(marked_indices[i], encoded[i])

    return res


def getModel(model_name: str) -> dict:
    # Load the model back
    with open(model_name, 'rb') as file:
        loaded_model = pickle.load(file)
    with open('./models/encoder.pkl', 'rb') as file2:
        loaded_encoder = pickle.load(file2)
    with open('./models/labeled_encoder.pkl', 'rb') as file3:
        loaded_label_encoder = pickle.load(file3)

    if (loaded_model and loaded_encoder and loaded_label_encoder):
        return {
            'model': loaded_model,
            'encoders': loaded_encoder,
            'label_encoder': loaded_label_encoder
        }
    else:
        return "There's no model chosen"


def predict(modelDict: dict, inputs: list) -> str:
    print(inputs)
    inputs = np.array(inputs).reshape(1, -1)
    # Example inputs: ['Male', 'Urban', 'Under Graduate', 'Laptop', 'Middle Class', 'No', 'Yes', 'No', 'No', 'No', '91-100', 'Practical']
    prediction = modelDict['model'].predict(inputs)
    res = modelDict['label_encoder'].inverse_transform(prediction)

    return res

@app.route('/result', methods=['POST', 'GET'])
def result():
    if request.method == 'POST':
        data = json.loads(request.data)
        model = data['model']
        inputs = data['inputs']


        modelDict = getModel(f'./models/logistic.pkl')    # Only support logistic_prediction for now
        processed_input = processInput(inputs, modelDict['encoders'])
        res = predict(modelDict, processed_input)[0]

    return {
        'prediction': res
    }


# Run the app
if __name__ == '__main__':
    app.run(debug=True)
