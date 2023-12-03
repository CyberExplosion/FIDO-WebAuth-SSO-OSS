export const models = [
    {
        modelName: 'Logistic Regression',
        modelDetails: 'Created using different technique to classify',
        
        modelPicPath: '/frontPics/logistic.jpg',
        modelPageURL: '/model?pageName=Logistic+Regression'
    },
    {
        modelName: 'Neural Network',
        modelDetails: 'Created using different technique to classify',
        modelPicPath: '/frontPics/nn.jpg',
        modelPageURL: '/model?pageName=Neural+Network'
    },
    {
        modelName: 'Naive Gaussian Bayesian Network',
        modelDetails: 'Created using different technique to classify',
        modelPicPath: '/frontPics/bayes.png',
        modelPageURL: '/model?pageName=Naive+Gaussian+Bayesian+Network'
    },
    {
        modelName: 'Support Vector Machines',
        modelDetails: 'Created using different technique to classify',
        modelPicPath: '/frontPics/svm2.png',
        modelPageURL: '/model?pageName=Support+Vector+Machines'
    },
]

export const modelPageContents = {
    'Pre-Processing': {
        'title': 'Pre-Processing',
        'details': '',
        'imgList': ['/graphs/compareValue.png', '/graphs/heatmap.png'],
        'confusion': '',
        'report': '',
        'graphs': []
    },
    'Logistic Regression': {
        'title': 'Logistic Regression',
        'details': 'Our confusion matrix from the Logistic Regression shows that we predicted 150 averages, 35 bad, and 29 good. The model in terms of prediction did fair as its predicted 62% correctly. The model was able to correctly predict "average" correctly most of the time with a accuracy rate of 71%.',
        'imgList': ['/graphs/logistic matrix.svg', '/graphs/logistic report.svg'],
        'confusion': '/graphs/logistic matrix.svg',
        'report': '/graphs/logistic report.svg',
        'graphs': [],
        'modelPicPath': '/frontPics/logistic.jpg',
    },
    'Neural Network': {
        'title': 'Neural Network',
        'details': 'Using Artificial Neural Network, we have the model before hyper tuning and after hyper tuning. Before hyper tuning, the accuracy is 59%. It\'s able to predict your level of satisfaction in online education with 69% if it\'s average, with 47% if it\'s bad, and 42% if it\'s good. After hyper tuning, the model\'s accuracy is 58%. The epoches reduces from 250 to 63.. It has the accuracy of 67% for average satisfaction, 51% for bad satisfaction, and 41% for good satisfaction.',
        'imgList': ['/graphs/nn matrix after.png', '/graphs/nn after report.svg', '/graphs/nn_before_tuning.png', '/graphs/nn_after_tuning.png', '/graphs/nn matrix b4.png', '/graphs/nn b4 report.svg'],
        'confusion': '/graphs/nn matrix after.png',
        'report': '/graphs/nn after report.svg',
        'graphs': ['/graphs/nn_before_tuning.png', '/graphs/nn_after_tuning.png']
    },
    'Naive Gaussian Bayesian Network': {
        'title': 'Naive Gaussian Bayesian Network',
        'details': 'Using the Naive Gaussian Bayesian model, the accuracy of the model is 64%. The predicted model was able to predict 132 averages while the acutal was 105 average. The model was able to predict average the highest with an accuracy of 72%. It was also able to predict bad and good 56% and 51% respectively. Oversampling does not help the accuracy as much. Using several kernals does not increase the accuracy.',
        'imgList': ['/graphs/bayes matrix.svg', '/graphs/bayes report linear.svg', '/graphs/bayes report rbf.svg', '/graphs/bayes report poly.svg', '/graphs/bayes report sigmoid.svg'],
        'confusion': '/graphs/bayes matrix.svg',
        'report': '/graphs/bayes report linear.svg',
        'graphs': ['/graphs/bayes report rbf.svg', '/graphs/bayes report poly.svg', '/graphs/bayes report sigmoid.svg'],
        'modelPicPath': '/frontPics/bayes.png',
    },
    'Support Vector Machines': {
        'title': 'Support Vector Machines',
        'details': 'Using SVM, our accuracys was low. We oversampled the data with the linear and rbf kernal which gives us 27% accuracy for both kernals. The confusion matrix shows the linear kernal. The SVM predicted 162 averages while the actual data was only 112 averages. SVM did not correctly predict the satisfication level of students to a high enough accuracy.',
        'imgList': ['/graphs/svm matrix normalized.svg', '/graphs/svm report linear.svg', '/graphs/svm matrix Confusion matrix, without normalization.svg', '/graphs/svm report rbf.svg'],
        'confusion': '/graphs/svm matrix normalized.svg',
        'report': '/graphs/svm report linear.svg',
        'graphs': ['/graphs/svm matrix Confusion matrix, without normalization.svg', '/graphs/svm report rbf.svg'],
        'modelPicPath': '/frontPics/svm2.png',
    },
}