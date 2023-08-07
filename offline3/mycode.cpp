#include <iostream>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <chrono>
#include <random>
#include <algorithm>
#include <vector>
#include <random>
using namespace std;
#define NumberOfPrintStation 4
#define SEED 1234


class student{
    public:
        pthread_t th;
        int studentId;
        int arrivalTime,printingTime,bindingTime,writingTime,printStationId,state;
        bool leader;

        //0->idle
        //1->queue
        //2->print

        student(int studentId){
            this->studentId=studentId;
            state=0;
            leader=false;
            printStationId=(studentId+1)%NumberOfPrintStation+1;
        }
};

int totalStudent,studentPerGroup;
vector<student>allStudents;
default_random_engine generateRandom(SEED);

//semaphores
pthread_mutex_t mutaxLock;
vector<sem_t> printingSemaphore(100);
sem_t bindingSemaphore;
long long int startTime;


void* studentActivities(void* arg);

void initializeAll(int studentCount,int w,int x,int y){
    for(int i=0;i<studentCount;i++){
        student s(i);
        allStudents.push_back(s);
    }
    
    //setting delays
    poisson_distribution<int>distribution1(3); //for arrival time unit
    poisson_distribution<int>distribution2(w); //for printing time unit
    poisson_distribution<int>distribution3(x); //for binding time unit
    poisson_distribution<int>distribution4(y); //for writing time unit

    for(int i=0;i<studentCount;i++){
        //applicable for all students
        allStudents[i].arrivalTime=distribution1(generateRandom);
        allStudents[i].printingTime=distribution2(generateRandom);

        //applicable for only group leader
        if((i%studentPerGroup)==studentPerGroup-1){
            allStudents[i].leader=true;
            allStudents[i].bindingTime=distribution3(generateRandom);
            allStudents[i].writingTime=distribution4(generateRandom);
        }
    }

    //semaphore init
    pthread_mutex_init(&mutaxLock,0);
    for(int i=0;i<studentCount;i++){
        sem_init(&printingSemaphore[i],0,0);
    }
    sem_init(&bindingSemaphore,0,2);

    startTime=time(NULL);
}

void print(int studentId){
    bool flag=true;
    int printingStationId=allStudents[studentId].printStationId;

    for(int i=0;i<totalStudent;i++){
        if(allStudents[i].state==2 && allStudents[i].printStationId==printingStationId){
            flag=false;
            break;
        }
    }

    if(flag && allStudents[studentId].state==1){
        allStudents[studentId].state=2;
        sem_post(&printingSemaphore[studentId]);
    }
}

void startPrinting(int studentId){
    pthread_mutex_lock(&mutaxLock);
    allStudents[studentId].state=1; //in queue
    print(studentId);
    pthread_mutex_unlock(&mutaxLock);
    sem_wait(&printingSemaphore[studentId]);
}

void endPrinting(int studentId){
    pthread_mutex_lock(&mutaxLock);

    allStudents[studentId].state=0;

    int i=(studentId+NumberOfPrintStation)%totalStudent;
    do{
        print(i); //see if other students can print
        i=(i+NumberOfPrintStation)%totalStudent;
    }while(i!=studentId);

    pthread_mutex_unlock(&mutaxLock);
}

void printingStation(int studentId){
    //TASK 1:PRINTING
    sleep(allStudents[studentId].arrivalTime);

    cout<<"Student "<<studentId+1<<" has arrived at print station at time "<<time(NULL)-startTime<<endl;

    //printing task
    startPrinting(studentId);
    sleep(allStudents[studentId].printingTime);
    endPrinting(studentId);

    cout<<"Student "<<studentId+1 <<" has finished printing at time "<<time(NULL)-startTime<<endl;
}

void bindingStation(int studentId){
    //TASK 2:BINDING
    if(allStudents[studentId].leader){
        //wait to finish printing of all the other members of group
        int memberCount=studentPerGroup-1;
        for(int i=studentId-1;memberCount!=0;i--){
            pthread_join(allStudents[i].th,NULL);
            memberCount--;
        }

        cout << "Group " << studentId / studentPerGroup + 1 << " has finished printing at time " << time(NULL) - startTime << endl;
        
        //binding
        sem_wait(&bindingSemaphore);
        cout<<"Group "<<studentId/studentPerGroup+1<<" has started binding at time "<<time(NULL)-startTime<<endl;
        sleep(allStudents[studentId].bindingTime);
        sem_post(&bindingSemaphore);
        cout<<"Group "<<studentId/studentPerGroup+1<<" has finished binding at time "<<time(NULL)-startTime<<endl;
    }
}

void* studentActivities(void* arg){
    int studentId=*(int*)arg; //random order

    printingStation(studentId);

    bindingStation(studentId);

}


int main(){
    int w,x,y;
    freopen("input.txt","r",stdin);
    cin>>totalStudent>>studentPerGroup>>w>>x>>y;

    vector<int>randomSerial(totalStudent);

    for(int i=0;i<totalStudent;i++){
        randomSerial[i]=i;
    }
    random_shuffle(randomSerial.begin(),randomSerial.end());

    initializeAll(totalStudent,w,x,y);

    //init thread
    for(int i=0;i<totalStudent;i++){
        pthread_create(&(allStudents[randomSerial[i]].th),NULL,studentActivities,(void*)&randomSerial[i]);
    }

    for (int i = 0; i < totalStudent; i++){
	    if (allStudents[i].leader)
		pthread_join(allStudents[i].th, NULL);
    }

    for(int i=0;i<printingSemaphore.size();i++){
        sem_destroy(&printingSemaphore[i]);
    }

    return 0;

}