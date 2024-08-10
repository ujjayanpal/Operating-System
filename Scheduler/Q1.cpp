#include <bits/stdc++.h>
#include <fstream>
#include <iostream>

using namespace std;
struct process {
  int pid;
  int a_time;
  int na_time;
  int b_time;
  int r_time;
  int ut;
  int q;
  int ct;
  int pq;
};
bool mycomp0(struct process *p1, struct process *p2) {
  if (p1->na_time < p2->na_time) {
    return true;
  }
  if (p1->na_time == p2->na_time && p1->pid < p2->pid) {
    return true;
  }
  return false;
}
bool mycomp1(struct process *p1, struct process *p2) {
  if (p1->r_time < p2->r_time) {
    return true;
  } else if (p1->r_time == p2->r_time && p1->pid < p2->pid) {
    return true;
  }
  return false;
}
bool mycomp2(struct process *p1, struct process *p2) {
  if (p1->na_time < p2->na_time) {
    return true;
  } else if (p1->na_time == p2->na_time && p1->pid < p2->pid) {
    return true;
  }
  return false;
}
int main() {

  int TS;
  int TT;
  string IN, ON;
  cin >> TS >> TT;
  cin >> IN >> ON;
  ifstream cin(IN);
  ofstream cout(ON);
  int a, b, c, d;
  bool bb = false, cc = false, ll = false;
  map<int, struct process *> vec;
  unordered_map<int, vector<struct process *>> mp;
  vector<struct process *> Q[4];
  // vector<string> stg(4, "");
  // string arr[4] = {"1", "2", "3", "4"};
  vector<vector<struct process *>> ve(4);
  int n = 0;
  while (!cin.eof()) {
    cin >> a >> b >> c >> d;
    n++;
    struct process *p = new struct process;
    p->pid = a;
    p->q = b;
    p->ut = 0;
    p->a_time = c;
    p->b_time = d;
    p->r_time = d;
    p->na_time = c;
    p->pq = b;
    vec[a - 1] = p;
    if (mp.count(p->a_time) == 0) {
      vector<struct process *> vec;
      mp[p->a_time] = vec;
      mp[p->a_time].push_back(p);
    } else {
      mp[p->a_time].push_back(p);
    }
  }
  int t = -1;
  while (n > 0) {
    t++;
    int ii = 3;
    if (mp.count(t) > 0) {
      for (auto z : mp[t]) {
        ve[(z->q) - 1].push_back(z);
      }
    }
    if (ve[3].size() > 1) {
      sort(ve[3].begin(), ve[3].end(), mycomp0);
    }
    sort(ve[2].begin(), ve[2].end(), mycomp1);
    sort(ve[1].begin(), ve[1].end(), mycomp1);
    for (int i = 3; i >= 0; i--) {
      for (auto z : ve[i]) {
        Q[i].push_back(z);
      }
      ve[i].clear();
    }
    if (ll == false && Q[3].size() >= 1) {
      Q[3].push_back(Q[3][0]);
      Q[3].erase(Q[3].begin());
    }
    /*if (bb == false && Q[2].size() > 1) {
      sort(Q[2].begin(), Q[2].end(), mycomp1);
    } else if (Q[2].size() > 1) {
      sort(Q[2].begin() + 1, Q[2].end(), mycomp1);
    }
    if (cc == false && Q[1].size() > 1) {
      sort(Q[1].begin(), Q[1].end(), mycomp1);
    } else if (Q[1].size() > 1) {
      sort(Q[1].begin() + 1, Q[1].end(), mycomp1);
    }*/
    bb = true;
    cc = true;
    ll = true;
    while (ii >= 0 && Q[ii].size() == 0) {
      // stg[ii] += " ";
      ii--;
    }
    if (ii < 0) {
      continue;
    } else {
      if (ii == 3) {
        // stg[2] += " ";
        // stg[1] += " ";
        // stg[0] += " ";
        // stg[3] += arr[Q[ii][0]->pid - 1];
        Q[ii][0]->r_time--;
        Q[ii][0]->ut++;
        if (Q[ii][0]->ut == TS) {
          Q[ii][0]->ut = 0;

          if (Q[ii][0]->r_time == 0) {
            n--;
            Q[ii][0]->ct = t + 1;
            Q[ii].erase(Q[ii].begin());
          } else {
            ll = false;
            // Q[3].push_back(Q[3][0]);
            // Q[3].erase(Q[3].begin());
          }
        } else if (Q[ii][0]->r_time == 0) {
          n--;
          Q[ii][0]->ct = t + 1;
          Q[ii].erase(Q[ii].begin());
          bb = false;
        }
      } else if (ii == 2 || ii == 1) {
        int index = 0;
        if (Q[ii][0]->ut == 0) {
          for (int jj = 0; jj < Q[ii].size(); jj++) {
            if (mycomp1(Q[ii][jj], Q[ii][index])) {
              index = jj;
            }
          }
          struct process *pp = Q[ii][index];
          Q[ii].erase(Q[ii].begin() + index);
          Q[ii].insert(Q[ii].begin(), pp);
        }
         //stg[0] += " ";
         //if (ii == 2) {
         //stg[2] += arr[Q[ii][0]->pid - 1];
         //stg[1] += " ";
        //} else {
         //stg[1] += arr[Q[ii][0]->pid - 1];
        //}
        Q[ii][0]->ut++;
        Q[ii][0]->r_time--;
        if (Q[ii][0]->r_time == 0) {
          n--;
          Q[ii][0]->ct = t + 1;
          Q[ii].erase(Q[ii].begin());
          if (ii == 2) {
            bb = false;
          } else {
            cc = false;
          }
        }
      } else {
        //stg[0] += arr[Q[ii][0]->pid - 1];
        Q[ii][0]->ut++;
        Q[ii][0]->r_time--;
        if (Q[ii][0]->r_time == 0) {
          n--;
          Q[ii][0]->ct = t + 1;
          Q[ii].erase(Q[ii].begin());
        }
      }
    }
    for (int ii = 2; ii >= 0; ii--) {
      for (auto it = Q[ii].begin(); it < Q[ii].end(); it++) {
        if (t + 1 - (*it)->na_time - (*it)->ut >= TT) {
          (*it)->ut = 0;
          (*it)->pq++;
          (*it)->na_time = t + 1;
          if (ii == 2 && it == Q[2].begin()) {
            bb = false;
          } else if (ii == 1 && it == Q[1].begin()) {
            cc = false;
          }
          ve[ii + 1].push_back(*it);
          Q[ii].erase(it);
          it--;
        }
      }
    }
  }
  int max_tat = 0;
  for (auto zz : vec) {
    max_tat = max(max_tat, (zz.second->ct) - (zz.second->a_time));
  }
  int mtt = 0;
  for (int ii = 0; ii < vec.size(); ii++) {
    mtt += (vec[ii]->ct) - (vec[ii]->a_time);
    cout << "ID: " << vec[ii]->pid << "; Orig. Level: " << vec[ii]->q
         << "; Final Level: " << vec[ii]->pq
         << "; Comp. Time(ms): " << (vec[ii]->ct)
         << "; TAT (ms): " << (vec[ii]->ct) - (vec[ii]->a_time) << endl;
  }
  double d1 = (1.0000)*mtt / vec.size();
  double d2 = ((1.0000)*vec.size()*(1000)) / max_tat;
  cout << "Mean Turnaround time:  " << (ceil(d1*100.0))/100.0
       << " ms/process; Throughput: " << (ceil(d2*100.0))/100.0
       << " processes/sec" << endl;
   //cout<<stg[3]<<endl;
   //cout<<stg[2]<<endl;
   //cout<<stg[1]<<endl;
   //cout<<stg[0]<<endl;
  return 0;
}