//
//  Solver.h
//  Solver
//
//  Created by Khang Lam on 5/25/18.
//  Copyright © 2018 Khang Lam. All rights reserved.
//

#ifndef Solver_hpp
#define Solver_hpp
#include <set>
#include <unordered_set>



using namespace std;
using namespace cv;

template<size_t num>

class Solver
{
public:
    
    Solver() : sudoku_grid(num*num,vector<unordered_set<char>>(num*num))
    {
        for(size_t x=0; x<num*num; ++x)
        {
            //      cout<<"TEST 1"<<endl;
            constraints.push_back(RestrictForCol(x));
            constraints.push_back(RestrictForRow(x));
            constraints.push_back(WallRestriction(x));
        }
    }
    
    

    void set_value(size_t X, size_t Y, char input)
    {
        //  cout<<input<<endl;
        if (input==0)
        {
            //cout<<input<<endl;
            for(char i=0; i<num*num; ++i)
            {
                //  cout<<i<<endl;
                sudoku_grid[X][Y].insert(i+1);
            }
        }
        else
        {
            // cout<<input<<endl;
            sudoku_grid[X][Y].insert(input);
        }
    }
    char get_value(size_t X, size_t Y)
    {
        if(sudoku_grid[X][Y].size()==1)
            return *sudoku_grid[X][Y].begin();
        else
            return 0;
    }
    
    
    

    bool isSolved()
    {
        bool solved = true;
        for(size_t x=0; x<num*num; ++x)
            for(size_t y=0; y<num*num; ++y)
                if(sudoku_grid[x][y].size()!=1)
                {
                    solved = false;
                    x = num*num;
                    y = num*num;
                   // return solved;
                }
        return solved;
    }
    
    bool solve()
    {
        
        size_t MAX = 1000;
        size_t count = 0;
        int iter=0;
        while(isSolved() == false)
        {
            
            //  iter<<iter++<<endl;
          
            for(auto constr:constraints)
                constr.detect_board(sudoku_grid);
            count++;
            if(count>MAX)
                return false;
        }
        return true;
    }
private:
    
    struct Restrict
    {
  
        Restrict(): row(num*num), col(num*num)
        {
        }
        
     
        string temp;
        
    
        vector<size_t> row;
        vector<size_t> col;
        

        bool detect_board(vector<vector<unordered_set<char>>>& contain)
        {
            bool IS_SOLVED = false;
            
      
            unordered_set<char> choices;
            for(char x=0; x<num*num; ++x)
                choices.insert(x+1);
     
            unordered_set<char> correct;
            for(size_t x=0; x<num*num; ++x)
            /*  stringstream inputStream;
             inputStream << row;
             this->temp = "Row "+inputStream.str();*/
                if (contain[row[x]][col[x]].size()==1)
                    correct.insert(*(contain[row[x]][col[x]].begin()));
            
         
            for(size_t x=0; x<num*num; ++x)
                if (contain[row[x]][col[x]].size()>1)
                {
                    for(auto er:correct)
                        contain[row[x]][col[x]].erase(er);
                    /*        for(size_t x=0; x<num*num; ++x)
                     for(size_t y=0; y<num*num; ++y)
                     if(sudoku_grid[x][y].size()!=1)
                     {
                     solved = false;
                     x = num*num;
                     y = num*num;*/
                    if(contain[row[x]][col[x]].size()==1)
                        IS_SOLVED = true;
                    
                }
            
            return IS_SOLVED;
        }
    };
    

    struct RestrictForRow: public Restrict //row restrition
    {
 
        RestrictForRow(size_t row)
        {
           
            for(size_t x=0; x<num*num; ++x)
            {
                //stringstream inputStream;
                // inputStream << col;
                this->row[x] = row;
                this->col[x] = x;
            }
            
          
            stringstream inputStream;
            
            inputStream << row;
            this->temp = "Row "+inputStream.str();
        }
        
    };
    

    struct RestrictForCol: public Restrict //Col restrictions
    {
      
        RestrictForCol(size_t col)
        {
          
            for(size_t x=0; x<num*num; ++x)
            {
                //stringstream inputStream;
               // inputStream << col;
                this->col[x] = col;
                this->row[x] = x;
            }
            
   
            stringstream inputStream;
            inputStream << col;
            this->temp = "Col "+inputStream.str();
        }
    };
    

    struct WallRestriction: public Restrict //For the block restrictions
    {
       
        WallRestriction(size_t wall)
        {
            
            size_t x_res = wall%3;
            size_t y_res = floor(wall/3);
            size_t position = 0;
            for(size_t x=0; x<num; ++x)
            {
                for(size_t y=0; y<num; ++y)
                {
                    //stringstream inputStream;
                    // inputStream << col;
                    this->col[position] = x+x_res*num;
                    this->row[position] = y+y_res*num;
                    position++;
                }
            }
            
        
            stringstream inputStream;
            inputStream << wall;
            //stringstream inputStream;
            // inputStream << col;
            this->temp = "Wall "+inputStream.str();
        }
    };
    
    vector<Restrict> constraints;
    vector<vector<unordered_set<char>>> sudoku_grid;
};

#endif /* Solver_hpp */

