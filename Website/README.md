# Website
Website for the Machine Learning Website


## Main Project Repo:
[ECS-171-Online-Study](https://github.com/ECS-171-Divorce-Team/ECS-171-Online-Study)

## Project Breakdown:
1) Design the Lo-Fi of the page

At this stage we will:
- Explore what should go on the webpage
- The scale of the website
- Member brainstorm and idea to be on the website

> We should always asking for other opinion on how our page should look

2) Design the Hi-Fi of the page

At this stage we will:
- Decide what kind of layout would go well with a Machine Learning showcases webpage
- Solidified the content we want to show on the page.

**The next step will happen concurrently with the previous two**

1) Developing the Front-End for the project
- Using NextJS as skeleton. We implement the Hi-Fi design to a real page.
2) Developing the Back-End for the project
- Find out what backend technology and see if its' fathomable to develop a full backend for our website.

## Running the project
### Requirement
1. You will need NodeJS to develop and run our project. Please install the following:

[Node.js Download Page](https://nodejs.org/en/download/)
After installing please verified on your machine by typing these on the terminal:
```bash
node -v
npm -v
```
If there isn't any output. Please try restart your computer or re-install Node.js


2. Install dependencies required by nextJS
    * This is a [Next.js](https://nextjs.org/) project bootstrapped with [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app).
    * We also use [React-Bootstrap](https://react-bootstrap.github.io/) to increase our development speed.

> Make sure you inside our repo folder from this step onward

Enter this on your terminal:
```bash
# Move into the front-end folder
cd online-study-website

# Use node to install all dependencies
npm install
```


3. We use [Flask](https://flask.palletsprojects.com/en/2.1.x/) for our backend and thus you need to have Flask install on your machine

Enter this on your terminal:
```bash
pip install Flask
```

4. Any dependencies that our Machine Learning project requires:

View our project GitHub Page README.md and follow the Requirements to install all the ML dependencies necessary:

[Our main Project Page](https://github.com/ECS-171-Divorce-Team/ECS-171-Online-Study)

### Running the Project

* First, run the front-end development server:

```bash
# Go to the front-end nextJS folder
cd online-study-website

npm run dev
# or
yarn dev
```
* Then on another terminal, run the back-end server:
```bash
# Go to the back-end folder
cd backend

python server.py
# or
python3 server.py
```

* Leave those 2 terminals open and go to the next
### Viewing the Webpage
Go to [http://localhost:3000/](http://localhost:3000/) to view our Webpage after finish all the steps above.

## Live Homepage
We also have the front-end webpage fully online hosted by Vercel. The backend is not supported so we only have the front-end working:

[Our Project Page](https://website-ecs-177-online-studying.vercel.app/)
